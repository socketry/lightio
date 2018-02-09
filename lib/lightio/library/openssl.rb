require 'openssl'
module LightIO::Library
  module OpenSSL
    module SSL
      class SSLSocket
        include Base
        include LightIO::Wrap::IOWrapper

        mock ::OpenSSL::SSL::SSLSocket
        prepend LightIO::Library::IO::IOMethods

        wrap_blocking_methods :connect, :accept

        def initialize(io, *args)
          io = io.send(:light_io_raw_obj) if io.is_a?(LightIO::Library::IO)
          super(io, *args)
        end

        def accept_nonblock
          socket = @obj.accept_nonblock(*args)
          socket.is_a?(Symbol) ? socket : self.class._wrap(socket)
        end
      end
    end
  end
end
