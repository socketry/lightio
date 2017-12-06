# Example from https://github.com/socketry/nio4r/blob/master/examples/echo_server.rb
# rewrite it in lightio for demonstrate

require 'lightio'
require 'socket'

class EchoServer
  def initialize(host, port)
    @server = TCPServer.new(host, port)
  end

  def run
    # wait server readable
    # +wait_read+ is one of LightIO IOPrimitive
    while LightIO.wait_read(@server)
      socket = @server.accept
      _, port, host = socket.peeraddr
      puts "accept connection from #{host}:#{port}"

      # LightIO::Beam is lightweight executor, provide thread-like interface
      # just start new beam for per socket
      LightIO::Beam.new(socket) do |socket|
        while LightIO.wait_read(socket)
          echo(socket)
        end
      end
    end
  end

  def echo(socket)
    data = socket.read_nonblock(4096)
    socket.write_nonblock(data)
  rescue EOFError
    _, port, host = socket.peeraddr
    puts "*** #{host}:#{port} disconnected"
    socket.close
  end
end


EchoServer.new('localhost', 3000).run if __FILE__ == $0
