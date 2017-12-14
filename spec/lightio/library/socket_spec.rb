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
    data = socket.read(4096)
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
  describe "#accept & #connect" do
    let(:port) {pick_random_port}
    let(:beam) {LightIO::Beam.new do
      LightIO::TCPServer.open(port) {|serv|
        s, addr = serv.accept
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
      rescue Errno::ECONNREFUSED
        beam.join(0.0001)
        retry
      end
      beam.join(0.0001)
      expect(client.gets).to be == "#{Date.today.to_s}\n"
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
          response << client.read(4096)
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
          response << client.read(4096)
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
end
