require 'socket'
module LightIO::Library

  class BasicSocket < IO
    include LightIO::Wrap::Wrapper
    wrap ::BasicSocket

    wrap_blocking_methods :recv, :recvmsg, :sendmsg

    class << self
      def for_fd(fd)
        Socket._wrap(raw_class.for_fd(fd))
      end
    end
  end

  class Socket < BasicSocket
    include ::Socket::Constants
    include LightIO::Wrap::Wrapper
    wrap ::Socket

    wrap_blocking_methods :connect, :recvfrom

    ## implement ::Socket instance methods
    def accept
      socket, addrinfo = wait_nonblock(:accept_nonblock)
      [Socket._wrap(socket), LightIO::Library::Addrinfo._wrap(addrinfo)]
    end

    def sys_accept
      @io_watcher.wait_readable
      @io.sys_accept
    end

    # bind addr?

    class << self
      ## implement ::Socket class methods
      wrap_methods_run_in_threads_pool :getaddrinfo, :gethostbyaddr, :gethostbyname, :gethostname, :getifaddrs,
                                       :getnameinfo, :getservbyname

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
    include LightIO::Wrap::Wrapper
    wrap ::IPSocket

    class << self
      wrap_methods_run_in_threads_pool :getaddress
    end
  end

  class TCPSocket < IPSocket
    include LightIO::Wrap::Wrapper
    wrap ::TCPSocket
    wrap_methods_run_in_threads_pool :gethostbyname
  end

  class TCPServer < TCPSocket
    include LightIO::Wrap::Wrapper
    wrap ::TCPServer

    ## implement ::Socket instance methods
    def accept
      socket = wait_nonblock(:accept_nonblock)
      Socket._wrap(socket)
    end

    def sys_accept
      @io_watcher.wait_readable
      @io.sys_accept
    end
  end
end