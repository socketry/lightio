require 'socket'

module LightIO::Library

  class Addrinfo
    include Base
    include LightIO::Wrap::Wrapper

    mock ::Addrinfo
    extend LightIO::Module::Addrinfo::ClassMethods

    module WrapHelper
      protected
      def wrap_socket_method(method)
        define_method method do |*args|
          socket = self.class.wrap_to_library(@obj.send(method, *args))
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
          result = @obj.send(method, *args)
          if result.is_a?(::Addrinfo)
            self.class.wrap_to_library(result)
          elsif result.respond_to?(:map)
            result.map {|r| self.class.wrap_to_library(r)}
          else
            result
          end
        end
      end

      def wrap_addrinfo_return_methods(*methods)
        methods.each {|m| wrap_addrinfo_return_method(m)}
      end
    end

    include LightIO::Module::Base::Helper
    extend WrapHelper

    wrap_socket_methods :bind, :connect, :connect_from, :connect_to, :listen
    wrap_addrinfo_return_methods :family_addrinfo, :ipv6_to_ipv4
  end

  class BasicSocket < LightIO::Library::IO
    include Base
    include LightIO::Wrap::IOWrapper
    mock ::BasicSocket
    extend LightIO::Module::BasicSocket::ClassMethods

    wrap_blocking_methods :recv, :recvmsg, :sendmsg

    extend Forwardable
    def_delegators :io_watcher, :wait, :wait_writable

    def shutdown(*args)
      # close watcher before io shutdown
      io_watcher.close
      @obj.shutdown(*args)
    end
  end

  class Socket < BasicSocket
    include Base
    include LightIO::Wrap::IOWrapper
    mock ::Socket
    extend LightIO::Module::Socket::ClassMethods

    wrap_blocking_methods :connect, :recvfrom, :accept

    def sys_accept
      io_watcher.wait_readable
      @obj.sys_accept
    end

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
      if socket.is_a?(Symbol)
        [socket, nil]
      else
        [self.class._wrap(socket), Addrinfo._wrap(addrinfo)]
      end
    end
  end


  class IPSocket < BasicSocket
    include Base
    mock ::IPSocket
  end

  class TCPSocket < IPSocket
    include Base
    mock ::TCPSocket
    wrap_methods_run_in_threads_pool :gethostbyname

    def initialize(*args)
      raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 2..4)" if args.size < 2 || args.size > 4
      host, port = args[0..1]
      local_host, local_port = args[2..3]
      addrinfo = Addrinfo.getaddrinfo(host, port, nil, :STREAM)[0]
      socket = ::Socket.send(:origin_new, addrinfo.afamily, Socket::SOCK_STREAM, 0)
      if local_host || local_port
        local_address = Socket.sockaddr_in(local_port, local_host)
        socket.bind(local_address)
      end
      remote_address = Socket.sockaddr_in(addrinfo.ip_port, addrinfo.ip_address)
      @obj = socket
      wait_nonblock(:connect_nonblock, remote_address)
      @obj
    end

    private
    def connect_nonblock(*args)
      @obj.connect_nonblock(*args)
    end
  end

  class TCPServer < TCPSocket
    include Base
    mock ::TCPServer

    def initialize(*args)
      @obj = ::TCPServer.send(:origin_new, *args)
    end

    def accept
      socket = wait_nonblock(:accept_nonblock)
      TCPSocket._wrap(socket)
    end

    def accept_nonblock(*args)
      socket = @obj.accept_nonblock(*args)
      socket.is_a?(Symbol) ? socket : TCPSocket._wrap(socket)
    end

    def sys_accept
      io_watcher.wait_readable
      @obj.sys_accept
    end
  end

  class UDPSocket < IPSocket
    include Base
    mock ::UDPSocket

    wrap_blocking_methods :recvfrom
  end

  class UNIXSocket < BasicSocket
    include Base
    mock ::UNIXSocket

    def send_io(io)
      io = io.send(:light_io_raw_obj) if io.is_a?(LightIO::Library::IO)
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

    def sys_accept
      io_watcher.wait_readable
      @obj.sys_accpet
    end

    def accept
      socket = wait_nonblock(:accept_nonblock)
      UNIXSocket._wrap(socket)
    end

    def accept_nonblock(*args)
      socket = @obj.accept_nonblock(*args)
      socket.is_a?(Symbol) ? socket : UNIXSocket._wrap(socket)
    end
  end
end
