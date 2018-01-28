require 'socket'

module LightIO::Module
  module Addrinfo
    include LightIO::Module::Base

    module WrapperHelper
      protected
      include LightIO::Module::Base::Helper

      def wrap_socket_method(method)
        define_method method do |*args|
          socket = wrap_to_library(@obj.send(method, *args))
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
            wrap_to_library(result)
          elsif result.respond_to?(:map)
            result.map {|r| wrap_to_library(r)}
          else
            result
          end
        end
      end

      def wrap_addrinfo_return_methods(*methods)
        methods.each {|m| wrap_addrinfo_return_method(m)}
      end

      def wrap_class_addrinfo_return_method(method)
        define_method method do |*args|
          result = super
          if result.is_a?(::Addrinfo)
            wrap_to_library(result)
          elsif result.respond_to?(:map)
            result.map {|r| wrap_to_library(r)}
          else
            result
          end
        end
      end

      def wrap_class_addrinfo_return_methods(*methods)
        methods.each {|m| wrap_class_addrinfo_return_method(m)}
      end
    end

    module ClassMethods
      extend WrapperHelper

      def foreach(*args, &block)
        Addrinfo.getaddrinfo(*args).each(&block)
      end

      wrap_class_addrinfo_return_methods :getaddrinfo, :ip, :udp, :tcp, :unix
    end
  end

  module BasicSocket
    include LightIO::Module::Base

    module ClassMethods
      include LightIO::Module::Base::Helper

      def for_fd(fd)
        wrap_to_library(super(fd))
      end
    end
  end

  module Socket
    include LightIO::Module::Base

    module ClassMethods
      include LightIO::Module::Base::Helper
      extend LightIO::Wrap::Wrapper::HelperMethods
      ## implement ::Socket class methods
      wrap_methods_run_in_threads_pool :getaddrinfo, :gethostbyaddr, :gethostbyname, :gethostname,
                                       :getnameinfo, :getservbyname

      def getifaddrs
        super.map {|ifaddr| LightIO::Library::Socket::Ifaddr._wrap(ifaddr)}
      end

      def socketpair(domain, type, protocol)
        super.map {|s| wrap_to_library(s)}
      end

      alias_method :pair, :socketpair

      def unix_server_socket(path)
        if block_given?
          super(path) {|s| yield wrap_to_library(s)}
        else
          wrap_to_library(super(path))
        end
      end

      def ip_sockets_port0(ai_list, reuseaddr)
        super(ai_list, reuseaddr).map {|s| wrap_to_library(s)}
      end
    end
  end


  module IPSocket
    include LightIO::Module::Base

    module ClassMethods
      extend LightIO::Wrap::Wrapper::HelperMethods
      wrap_methods_run_in_threads_pool :getaddress
    end
  end

  module TCPSocket
    include LightIO::Module::Base
  end

  module TCPServer
    include LightIO::Module::Base
  end

  module UDPSocket
    include LightIO::Module::Base
  end

  module UNIXSocket
    include LightIO::Module::Base

    module ClassMethods
      include LightIO::Module::Base::Helper

      def socketpair(*args)
        super(*args).map {|io| wrap_to_library(io)}
      end

      alias_method :pair, :socketpair
    end
  end

  module UNIXServer
    include LightIO::Module::Base
  end
end
