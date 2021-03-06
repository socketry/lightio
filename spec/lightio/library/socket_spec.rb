require 'spec_helper'
require 'date'
require 'socket'

class EchoServer
  def initialize(host, port)
    @server = LightIO::TCPServer.new(host, port)
  end

  def run
    while (socket = @server.accept)
      _, port, host = socket.peeraddr
      # puts "accept connection from #{host}:#{port}"

      # LightIO::Beam is lightweight executor, provide thread-like interface
      # just start new beam for per socket
      LightIO::Beam.new(socket) do |socket|
        while echo(socket)
        end
      end
    end
  end

  def echo(socket)
    data = socket.readpartial(4096)
    socket.write(data)
  rescue EOFError
    _, port, host = socket.peeraddr
    # puts "*** #{host}:#{port} disconnected"
    socket.close
    nil
  end

  def close
    @server.close
  end
end

RSpec.describe LightIO::Library::Socket do
  describe "inherited" do
    it "inherited correctly" do
      expect(LightIO::BasicSocket).to be < LightIO::IO
      expect(LightIO::Socket).to be < LightIO::BasicSocket
      expect(LightIO::IPSocket).to be < LightIO::BasicSocket
      expect(LightIO::TCPSocket).to be < LightIO::IPSocket
      expect(LightIO::TCPServer).to be < LightIO::TCPSocket
    end
  end

  describe "#accept & #connect" do
    let(:port) {pick_random_port}
    let(:beam) {LightIO::Beam.new do
      LightIO::TCPServer.open(port) {|serv|
        s = serv.accept
        expect(s).to be_a LightIO::Library::TCPSocket
        s.puts Date.today
        s.close
      }
    end}

    it "work with raw socket client" do
      begin
        client = TCPSocket.new 'localhost', port
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
      beam.join(0.0001)
      expect(client.gets).to be == "#{Date.today.to_s}\n"
      client.close
    end

    it "work with TCPSocket" do
      begin
        client = LightIO::Library::TCPSocket.new 'localhost', port
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
      beam.join(0.0001)
      expect(client.gets).to be == "#{Date.today.to_s}\n"
      client.close
    end

    it "work with Socket" do
      begin
        client = LightIO::Socket.new(LightIO::Socket::AF_INET, LightIO::Socket::SOCK_STREAM)
        client.connect LightIO::Socket.pack_sockaddr_in(port, '127.0.0.1')
      rescue Errno::EISCONN
        # mean connect is success before ruby 2.2.7 *_* en...
        nil
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
      beam.join(0.0001)
      expect(client.gets).to be == "#{Date.today.to_s}\n"
      client.close
    end
  end

  describe "#accept_nonblock" do
    let(:port) {pick_random_port}
    let(:beam) {LightIO::Beam.new do
      LightIO::TCPServer.open(port) {|serv|
        expect(serv).to be_a LightIO::Library::TCPServer
        LightIO::IO.select([serv])
        s = serv.accept_nonblock
        expect(s).to be_a LightIO::Library::TCPSocket
        s.puts Date.today
        s.close
      }
    end}

    it "work with raw socket client" do
      begin
        client = TCPSocket.new 'localhost', port
      rescue Errno::ECONNREFUSED
        beam.join(0.001)
        retry
      end
      beam.join(0.001)
      expect(client.gets).to be == "#{Date.today.to_s}\n"
      client.close
    end

    it "work with TCPSocket" do
      begin
        client = LightIO::Library::TCPSocket.new 'localhost', port
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
      beam.join(0.0001)
      expect(client.gets).to be == "#{Date.today.to_s}\n"
      client.close
    end
  end

  context "some methods should return correct type" do
    let(:port) {pick_random_port}
    let(:beam) {LightIO::Beam.new do
      LightIO::TCPServer.open(port) {|serv|
        s = serv.accept
        s.puts Date.today
        s.close
      }
    end}

    let (:client) {
      begin
        client = LightIO::TCPSocket.new 'localhost', port
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
    }

    # bind localhost seems have some problem on MACOS, it connect two fd and never release them(even call close).
    # so just don't close them to avoid duplication fd.
    after {
      #client.close
    }

    it "#for_fd" do
      s = LightIO::Socket.for_fd(client.fileno)
      expect(s).to a_kind_of(LightIO::Socket)
      s = LightIO::TCPSocket.for_fd(client.fileno)
      expect(s).to a_kind_of(LightIO::TCPSocket)
      s = LightIO::TCPServer.for_fd(client.fileno)
      expect(s).to a_kind_of(LightIO::TCPServer)
    end

    it "#to_io" do
      expect(client.to_io).to a_kind_of(LightIO::TCPSocket)
      s = LightIO::Socket.for_fd(client.fileno)
      expect(s.to_io).to a_kind_of(LightIO::Socket)
      s = LightIO::TCPSocket.for_fd(client.fileno)
      expect(s.to_io).to a_kind_of(LightIO::TCPSocket)
      s = LightIO::TCPServer.for_fd(client.fileno)
      expect(s.to_io).to a_kind_of(LightIO::TCPServer)

      r, w = LightIO::IO.pipe
      expect(r.to_io).to a_kind_of(LightIO::IO)
      r.close
      w.close
    end
  end


  describe "echo server and multi clients" do
    it "multi clients" do
      port = pick_random_port
      server = EchoServer.new('localhost', port)
      beam = LightIO::Beam.new do
        server.run
      end
      b1 = LightIO::Beam.new do
        client = LightIO::TCPSocket.new('localhost', port)
        response = ""
        3.times {
          msg = "hello from b1"
          client.write(msg)
          response << client.readpartial(4096)
          LightIO.sleep(0)
        }
        client.close
        response
      end
      b2 = LightIO::Beam.new do
        client = LightIO::TCPSocket.new('localhost', port)
        response = ""
        3.times {
          msg = "hello from b2"
          client.write(msg)
          response << client.readpartial(4096)
          LightIO.sleep(0)
        }
        client.close
        response
      end
      expect(b1.value).to be == "hello from b1hello from b1hello from b1"
      expect(b2.value).to be == "hello from b2hello from b2hello from b2"
      server.close
      expect {beam.value}.to raise_error(IOError)
    end
  end

  describe LightIO::Library::Socket::Ifaddr do
    it '#getifaddrs' do
      ifaddrs = LightIO::Library::Socket.getifaddrs
      ifaddrs.each do |ifaddr|
        [:addr, :broadaddr, :dstaddr, :netmask].each do |m|
          result = ifaddr.send(m)
          next if result.nil?
          expect(result).to be_kind_of(LightIO::Library::Addrinfo)
        end
      end
    end
  end
end

RSpec.describe LightIO::Library::TCPServer do
  describe "act as TCPServer" do
    it "#is_a?" do
      LightIO::TCPServer.open(pick_random_port) {|serv|
        obj = serv
        expect(obj).to be_a(LightIO::Library::TCPServer)
        expect(obj).to be_a(TCPServer)
        expect(obj).to be_a(LightIO::Library::TCPSocket)
        expect(obj).to be_a(TCPSocket)
        expect(obj).to be_a(LightIO::Library::IPSocket)
        expect(obj).to be_a(IPSocket)
        expect(obj).to be_a(LightIO::Library::BasicSocket)
        expect(obj).to be_a(BasicSocket)
        expect(obj).to be_a(LightIO::Library::IO)
        expect(obj).to be_a(IO)
        expect(obj).to be_kind_of(LightIO::Library::TCPServer)
        expect(obj).to be_kind_of(TCPServer)
      }
    end

    it "#instance_of?" do
      LightIO::TCPServer.open(pick_random_port) {|serv|
        obj = serv
        expect(obj).to_not be_an_instance_of(LightIO::Library::BasicSocket)
        expect(obj).to_not be_an_instance_of(BasicSocket)
        expect(obj).to_not be_an_instance_of(LightIO::Library::IO)
        expect(obj).to_not be_an_instance_of(IO)
        expect(obj).to be_an_instance_of(LightIO::Library::TCPServer)
        expect(obj).to be_an_instance_of(TCPServer)
      }
    end
  end
end

RSpec.describe LightIO::Library::UNIXServer do
  it '#send_io' do
    r, w = LightIO::Library::IO.pipe
    s1, s2 = LightIO::Library::UNIXSocket.pair
    s1.send_io w
    out = s2.recv_io

    expect(out.fileno).not_to eq(w.fileno)

    out.puts "hello" # outputs "hello\n" to standard output.
    out.close
    expect(r.gets).to eq("hello\n")
    r.close; w.close
  end
end
