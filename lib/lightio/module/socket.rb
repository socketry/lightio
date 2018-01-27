require 'socket'

module LightIO::Module
  module BasicSocket
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper

    wrap_blocking_methods :recv, :recvmsg, :sendmsg

    extend Forwardable
    def_delegators :@io_watcher, :wait, :wait_writable

    def shutdown(*args)
      # close watcher before io shutdown
      @io_watcher.close
      super
    end
  end

  module Socket
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper

    def self.prepended(mod)
      mod.singleton_class.prepend(ClassMethods)
    end

    wrap_blocking_methods :connect, :recvfrom, :accept

    def sys_accept
      @io_watcher.wait_readable
      super
    end

    module ClassMethods
      extend LightIO::Wrap::Wrapper::HelperMethods
      ## implement ::Socket class methods
      wrap_methods_run_in_threads_pool :getaddrinfo, :gethostbyaddr, :gethostbyname, :gethostname,
                                       :getnameinfo, :getservbyname
    end
  end


  module IPSocket
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper

    module ClassMethods
      extend LightIO::Wrap::Wrapper::HelperMethods
      wrap_methods_run_in_threads_pool :getaddress
    end
  end

  module TCPSocket
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper

    wrap_methods_run_in_threads_pool :gethostbyname
  end

  module TCPServer
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper
    wrap_blocking_methods :accept

    def sys_accept
      @io_watcher.wait_readable
      super
    end
  end

  module UDPSocket
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper

    wrap_blocking_methods :recvfrom
  end

  module UNIXSocket
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper
  end

  module UNIXServer
    include LightIO::Module::Base
    include LightIO::Wrap::IOWrapper

    def sys_accept
      @io_watcher.wait_readable
      super
    end
  end
end
