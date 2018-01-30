# Example from https://github.com/socketry/nio4r/blob/master/examples/echo_server.rb
# rewrite it in lightio for demonstrate
# this example demonstrate LightIO low-level API
# how to use ruby 'raw'(unpatched) socket with LightIO

require 'lightio'
require 'socket'

class EchoServer
  def initialize(host, port)
    @server = TCPServer.new(host, port)
  end

  def run
    # wait server until readable
    server_watcher = LightIO::Watchers::IO.new(@server, :r)
    while server_watcher.wait_readable
      socket = @server.accept
      _, port, host = socket.peeraddr
      puts "accept connection from #{host}:#{port}"

      # LightIO::Beam is lightweight executor, provide thread-like interface
      # just start new beam for per socket
      LightIO::Beam.new(socket) do |socket|
        socket_watcher = LightIO::Watchers::IO.new(socket, :r)
        begin
          while socket_watcher.wait_readable
            echo(socket)
          end
        rescue EOFError
          _, port, host = socket.peeraddr
          puts "*** #{host}:#{port} disconnected"
          # remove close socket watcher
          socket_watcher.close
          socket.close
        end
      end
    end
  end

  def echo(socket)
    data = socket.read_nonblock(4096)
    socket.write_nonblock(data)
  end
end


EchoServer.new('localhost', 3000).run if __FILE__ == $0
