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
          if io.is_a?(LightIO::Library::IO)
            @_wrapped_socket = io
            io = io.send(:light_io_raw_obj)
          end
          super(io, *args)
        end

        def accept_nonblock
          socket = @obj.accept_nonblock(*args)
          socket.is_a?(Symbol) ? socket : self.class._wrap(socket)
        end

        def to_io
          @_wrapped_socket || @obj.io
        end

        alias io to_io
      end
    end
  end
end
