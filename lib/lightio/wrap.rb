module LightIO::Wrap
  WRAPPERS = {}
  module Wrapper
    # wrap raw ruby io objects
    #
    # @param [IO, Socket]  io raw ruby io object
    def initialize(io=nil)
      @io ||= io
      @io_watcher ||= LightIO::Watchers::IO.new(@io)
    end

    def method_missing(method, *args)
      @io.public_send(method, *args)
    end

    def close(*args)
      # close watcher before io closed
      @io_watcher.close
      @io.close(*args)
    end

    def shutdown(*args)
      # close watcher before io shutdown
      @io_watcher.close
      @io.shutdown(*args)
    end

    protected
    def _wrap(io=nil)
      @io ||= io
      @io_watcher ||= LightIO::Watchers::IO.new(@io)
    end

    # wait io nonblock method
    #
    # @param [Symbol]  method method name, example: wait_nonblock
    # @param [args] args arguments pass to method
    def wait_nonblock(method, *args, exception_symbol: true)
      loop do
        begin
          result = if RUBY_VERSION > "2.3" && exception_symbol
                     @io.__send__(method, *args, exception: false)
                   else
                     @io.__send__(method, *args)
                   end
          case result
            when :wait_readable
              @io_watcher.wait_readable
            when :wait_writable
              @io_watcher.wait_writable
            else
              return result
          end
        rescue IO::WaitReadable
          @io_watcher.wait_readable
        rescue IO::WaitWritable
          @IO_watcher.wait_writable
        end
      end
    end

    # both works in class scope and singleton class scope
    module SingletonClassCommonMethods
      protected
      # run method in thread pool for performance
      def wrap_methods_run_in_threads_pool(*args)
        #TODO
      end
    end

    module ClassMethods
      # Wrap raw io objects
      def _wrap(io)
        # In case ruby stdlib return already patched Sockets, just do nothing
        if io.is_a? self
          io
        else
          # old new
          obj = allocate
          obj.send(:initialize, io)
          obj
        end
      end

      # override new method, return wrapped class
      def new(*args)
        io = raw_class.new(*args)
        _wrap(io)
      end

      include SingletonClassCommonMethods

      protected
      # wrap blocking method with "#{method}_nonblock"
      #
      # @param [Symbol]  method method name, example: wait
      def wrap_blocking_method(method, exception_symbol: true)
        define_method method do |*args|
          wait_nonblock(:"#{method}_nonblock", *args, exception_symbol: exception_symbol)
        end
      end

      def wrap_blocking_methods(*methods, exception_symbol: true)
        methods.each {|m| wrap_blocking_method(m, exception_symbol: exception_symbol)}
      end

      attr_reader :raw_class

      # Set wrapped class
      def wrap(raw_class)
        @raw_class=raw_class
        WRAPPERS[raw_class] = self
      end

      def method_missing(method, *args)
        raw_class.public_send(method, *args)
      end
    end

    class << self
      def new_and_wrap(*args)
        io = raw_class.new(*args)
        _wrap(io)
      end

      def included(base)
        base.send :extend, ClassMethods
        base.singleton_class.send :extend, SingletonClassCommonMethods
      end
    end
  end
end