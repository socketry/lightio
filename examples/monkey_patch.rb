require 'lightio'

# apply monkey patch as early as possible
# after monkey patch, it just normal ruby code
LightIO::Monkey.patch_all!


TCPServer.open('localhost', 3000) do |server|
  while (socket = server.accept)
    _, port, host = socket.peeraddr
    puts "accept connection from #{host}:#{port}"

    # Don't worry, Thread.new create green threads, it cost very light
    Thread.new(socket) do |socket|
      data = nil
      begin
        socket.write(data) while (data = socket.readpartial(4096))
      rescue EOFError
        _, port, host = socket.peeraddr
        puts "*** #{host}:#{port} disconnected"
        socket.close
      end
    end

  end
end
