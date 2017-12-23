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
      puts "accept connection from #{host}:#{port}"

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
    puts "*** #{host}:#{port} disconnected"
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

  describe "#for_fd" do
    let(:port) {pick_random_port}
    let(:beam) {LightIO::Beam.new do
      LightIO::TCPServer.open(port) {|serv|
        s = serv.accept
        s.puts Date.today
        s.close
      }
    end}

    it "return different types" do
      begin
        client = LightIO::TCPSocket.new 'localhost', port
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
      s = LightIO::Socket.for_fd(client.fileno)
      expect(s).to a_kind_of(LightIO::Socket)
      s = LightIO::TCPSocket.for_fd(client.fileno)
      expect(s).to a_kind_of(LightIO::TCPSocket)
      s = LightIO::TCPServer.for_fd(client.fileno)
      expect(s).to a_kind_of(LightIO::TCPServer)
      client.close
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

  describe LightIO::Library::Addrinfo do
    it '#bind return wrapped socket' do
      addrinfo = LightIO::Library::Addrinfo.tcp("127.0.0.1", 0)
      expect(addrinfo).to be_kind_of(LightIO::Library::Addrinfo)
      socket = addrinfo.bind
      expect(socket).to be_kind_of(LightIO::Library::Socket)
      socket.close
    end
  end
end
