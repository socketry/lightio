module LightIO::Wrap
  # wrapper for normal ruby objects
  module Wrapper
    # both works in class scope and singleton class scope
    module HelperMethods
      protected
      # run method in thread pool for performance
      def wrap_methods_run_in_threads_pool(*args)
        #TODO
      end
    end

    class << self
      def included(base)
        base.send :extend, HelperMethods
      end
    end
  end

  # wrapper for ruby io objects
  module IOWrapper
    # wrap raw ruby io objects
    #
    # @param [IO, Socket]  io raw ruby io object
    def initialize(*args)
      io = super
      @io_watcher ||= LightIO::Watchers::IO.new(io)
    end

    protected
    # wait io nonblock method
    #
    # @param [Symbol]  method method name, example: wait_nonblock
    # @param [args] args arguments pass to method
    def wait_nonblock(method, *args)
      loop do
        result = __send__(method, *args, exception: false)
        case result
          when :wait_readable
            @io_watcher.wait_readable
          when :wait_writable
            @io_watcher.wait_writable
          else
            return result
        end
      end
    end

    module ClassMethods
      # include Wrapper::ClassMethods
      protected
      # wrap blocking method with "#{method}_nonblock"
      #
      # @param [Symbol]  method method name, example: wait
      def wrap_blocking_method(method)
        define_method method do |*args|
          wait_nonblock(:"#{method}_nonblock", *args)
        end
      end

      def wrap_blocking_methods(*methods)
        methods.each {|m| wrap_blocking_method(m)}
      end
    end

    class << self
      def included(base)
        base.send :extend, ClassMethods
        base.send :include, Wrapper
      end
    end
  end
end