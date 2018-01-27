require 'socket'

module LightIO::Library

  class Addrinfo
    include LightIO::Wrap::Wrapper
    include Base
    mock ::Addrinfo

    module WrapperHelper
      protected
      def wrap_socket_method(method)
        define_method method do |*args|
          socket = Socket._wrap(@obj.send(method, *args))
          if block_given?
            begin
              yield socket
            ensure
              socket.close
            end
          else
            socket
          end
        end
      end

      def wrap_socket_methods(*methods)
        methods.each {|m| wrap_socket_method(m)}
      end

      def wrap_addrinfo_return_method(method)
        define_method method do |*args|
          result = (@obj || mock_klass).send(method, *args)
          if result.is_a?(mock_klass)
            _wrap(result)
          elsif result.respond_to?(:map)
            result.map {|r| _wrap(r)}
          else
            result
          end
        end
      end

      def wrap_addrinfo_return_methods(*methods)
        methods.each {|m| wrap_addrinfo_return_method(m)}
      end
    end

    extend WrapperHelper

    wrap_socket_methods :bind, :connect, :connect_from, :connect_to, :listen

    wrap_addrinfo_return_methods :family_addrinfo, :ipv6_to_ipv4

    class << self
      extend WrapperHelper

      def foreach(*args, &block)
        Addrinfo.getaddrinfo(*args).each(&block)
      end

      wrap_addrinfo_return_methods :getaddrinfo, :ip, :udp, :tcp, :unix
    end
  end

  class BasicSocket < LightIO::Library::IO
    include Base
    mock ::BasicSocket
    prepend LightIO::Module::BasicSocket

    class << self
      def for_fd(fd)
        self._wrap(mock_klass.for_fd(fd))
      end
    end
  end

  class Socket < BasicSocket
    include Base
    mock ::Socket
    prepend LightIO::Module::Socket

    class Ifaddr
      include Base
      mock ::Socket::Ifaddr

      def addr
        @obj.addr && Addrinfo._wrap(@obj.addr)
      end

      def broadaddr
        @obj.broadaddr && Addrinfo._wrap(@obj.broadaddr)
      end

      def dstaddr
        @obj.dstaddr && Addrinfo._wrap(@obj.dstaddr)
      end

      def netmask
        @obj.netmask && Addrinfo._wrap(@obj.netmask)
      end
    end

    include ::Socket::Constants
    Option = ::Socket::Option
    UDPSource = ::Socket::UDPSource
    SocketError = ::SocketError
    Addrinfo = Addrinfo

    def accept
      socket, addrinfo = wait_nonblock(:accept_nonblock)
      [self.class._wrap(socket), Addrinfo._wrap(addrinfo)]
    end

    def accept_nonblock(*args)
      socket, addrinfo = @obj.accept_nonblock(*args)
      [self.class._wrap(socket), Addrinfo._wrap(addrinfo)]
    end

    class << self
      def getifaddrs
        mock_klass.getifaddrs.map {|ifaddr| Ifaddr._wrap(ifaddr)}
      end

      def socketpair(domain, type, protocol)
        mock_klass.socketpair(domain, type, protocol).map {|s| _wrap(s)}
      end

      alias_method :pair, :socketpair

      def unix_server_socket(path)
        if block_given?
          mock_klass.unix_server_socket(path) {|s| yield _wrap(s)}
        else
          _wrap(mock_klass.unix_server_socket(path))
        end
      end

      def ip_sockets_port0(ai_list, reuseaddr)
        mock_klass.ip_sockets_port0(ai_list, reuseaddr).map {|s| _wrap(s)}
      end
    end
  end


  class IPSocket < BasicSocket
    include Base
    mock ::IPSocket
    prepend LightIO::Module::IPSocket
  end

  class TCPSocket < IPSocket
    include Base
    mock ::TCPSocket
    prepend LightIO::Module::TCPSocket
  end

  class TCPServer < TCPSocket
    include Base
    mock ::TCPServer
    prepend LightIO::Module::TCPServer

    def accept
      socket = wait_nonblock(:accept_nonblock)
      TCPSocket._wrap(socket)
    end

    def accept_nonblock(*args)
      socket = @obj.accept_nonblock(*args)
      socket.is_a?(::TCPSocket) ? TCPSocket._wrap(socket) : socket
    end
  end

  class UDPSocket < IPSocket
    include Base
    mock ::UDPSocket
    prepend LightIO::Module::UDPSocket
  end

  class UNIXSocket < ::BasicSocket
    include Base
    mock ::UNIXSocket
    prepend LightIO::Module::UNIXSocket

    class << self
      def socketpair(*args)
        mock_klass.socketpair(*args).map {|io| UNIXSocket._wrap(io)}
      end

      alias_method :pair, :socketpair
    end

    def send_io(io)
      io = io.instance_variable_get(:@obj) unless io.is_a?(::IO)
      @obj.send_io(io)
    end

    def recv_io(*args)
      io = @obj.recv_io(*args)
      if (wrapper = LightIO.const_get(io.class.to_s))
        return wrapper._wrap(io) if wrapper.respond_to?(:_wrap)
      end
      io
    end
  end

  class UNIXServer < UNIXSocket
    include Base
    mock ::UNIXServer
    prepend LightIO::Module::UNIXServer

    def accept
      socket = wait_nonblock(:accept_nonblock)
      UNIXSocket._wrap(socket)
    end

    def accept_nonblock(*args)
      socket = @obj.accept_nonblock(*args)
      UNIXSocket._wrap(socket)
    end
  end
end
