require 'socket'

module LightIO::Library

  class Addrinfo
    include LightIO::Wrap::Wrapper
    wrap ::Addrinfo

    module WrapperHelper
      protected
      def wrap_socket_method(method)
        define_method method do |*args|
          socket = Socket._wrap(@io.send(method, *args))
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
          result = (@io || raw_class).send(method, *args)
          if result.is_a?(raw_class)
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

  class BasicSocket < IO
    include LightIO::Wrap::IOWrapper
    wrap ::BasicSocket
    wrap_blocking_methods :recv, :recvmsg, :sendmsg

    extend Forwardable
    def_delegators :@io_watcher, :wait, :wait_writable

    def shutdown(*args)
      # close watcher before io shutdown
      @io_watcher.close
      @io.shutdown(*args)
    end

    class << self
      def for_fd(fd)
        self._wrap(raw_class.for_fd(fd))
      end
    end
  end

  class Socket < BasicSocket
    include ::Socket::Constants
    include LightIO::Wrap::IOWrapper
    wrap ::Socket

    wrap_blocking_methods :connect, :recvfrom

    ## implement ::Socket instance methods
    def accept
      socket, addrinfo = wait_nonblock(:accept_nonblock)
      [self.class._wrap(socket), Addrinfo._wrap(addrinfo)]
    end

    def sys_accept
      @io_watcher.wait_readable
      @io.sys_accept
    end

    Option = ::Socket::Option
    UDPSource = ::Socket::UDPSource
    SocketError = ::SocketError

    class Ifaddr
      include LightIO::Wrap::Wrapper
      wrap ::Socket

      def addr
        @io.addr && Addrinfo._wrap(@io.addr)
      end

      def broadaddr
        @io.broadaddr && Addrinfo._wrap(@io.broadaddr)
      end

      def dstaddr
        @io.dstaddr && Addrinfo._wrap(@io.dstaddr)
      end

      def netmask
        @io.netmask && Addrinfo._wrap(@io.netmask)
      end
    end

    class << self
      ## implement ::Socket class methods
      wrap_methods_run_in_threads_pool :getaddrinfo, :gethostbyaddr, :gethostbyname, :gethostname,
                                       :getnameinfo, :getservbyname

      def getifaddrs
        raw_class.getifaddrs.map {|ifaddr| Ifaddr._wrap(ifaddr)}
      end

      def socketpair(domain, type, protocol)
        raw_class.socketpair(domain, type, protocol).map {|s| _wrap(s)}
      end

      alias_method :pair, :socketpair

      def unix_server_socket(path)
        if block_given?
          raw_class.unix_server_socket(path) {|s| yield _wrap(s)}
        else
          _wrap(raw_class.unix_server_socket(path))
        end
      end

      def ip_sockets_port0(ai_list, reuseaddr)
        raw_class.ip_sockets_port0(ai_list, reuseaddr).map {|s| _wrap(s)}
      end
    end
  end


  class IPSocket < BasicSocket
    include LightIO::Wrap::IOWrapper
    wrap ::IPSocket

    class << self
      wrap_methods_run_in_threads_pool :getaddress
    end
  end

  class TCPSocket < IPSocket
    include LightIO::Wrap::IOWrapper
    wrap ::TCPSocket
    wrap_methods_run_in_threads_pool :gethostbyname
  end

  class TCPServer < TCPSocket
    include LightIO::Wrap::IOWrapper
    wrap ::TCPServer

    ## implement ::Socket instance methods
    def accept
      socket = wait_nonblock(:accept_nonblock)
      TCPSocket._wrap(socket)
    end

    def sys_accept
      @io_watcher.wait_readable
      @io.sys_accept
    end
  end
end
