# Example from https://github.com/socketry/nio4r/blob/master/examples/echo_server.rb
# rewrite it in lightio for demonstrate
# this example demonstrate LightIO Libraries API
# look LightIO::Library namespace to find more

require 'lightio'

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
        loop do
          echo(socket)
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
    raise
  end
end


EchoServer.new('localhost', 3000).run if __FILE__ == $0
