require 'socket'

module HelperMethods
  def pick_random_port
    socket = TCPServer.new(0)
    socket.addr[1]
  ensure
    socket.close
  end
end
