module LightIO
  module Monkey
    class PatchError < StandardError
    end

    SOCKET_PATCH_CONSTANTS = %w{IO Socket Socket::Ifaddr TCPServer TCPSocket BasicSocket Addrinfo IPSocket UDPSocket UNIXSocket UNIXServer}.freeze
    THREAD_PATCH_CONSTANTS = %w{Thread ThreadGroup Queue SizedQueue ConditionVariable Mutex ThreadsWait}.freeze

    @patched

    class << self
      def patch_all!
        patch_thread!
        patch_socket!
        patch_kernel!
      end

      def unpatch_all!
        unpatch_thread!
        unpatch_socket!
        unpatch_kernel!
      end

      def patched?(obj)
        patched.key?(obj) && !patched[obj]&.empty?
      end

      def patch_thread!
        require 'thread'
        THREAD_PATCH_CONSTANTS.each {|klass_name| patch!(klass_name)}
        patch_method!(Timeout, :timeout, LightIO::Timeout.method(:timeout))
      end

      def unpatch_thread!
        require 'thread'
        THREAD_PATCH_CONSTANTS.each {|klass_name| unpatch!(klass_name)}
        unpatch_method!(Timeout, :timeout)
      end

      def patch_socket!
        require 'socket'
        SOCKET_PATCH_CONSTANTS.each {|klass_name| patch!(klass_name)}
      end

      def unpatch_socket!
        require 'socket'
        SOCKET_PATCH_CONSTANTS.each {|klass_name| unpatch!(klass_name)}
      end

      def patch_kernel!
        patch_method!(Kernel, :sleep, LightIO.method(:sleep))
        patch_method!(Kernel, :select, LightIO::Library::IO.method(:select))
      end

      def unpatch_kernel!
        unpatch_method!(Kernel, :sleep, LightIO.method(:sleep))
        unpatch_method!(Kernel, :select, LightIO::Library::IO.method(:select))
      end

      private
      def patch!(klass_name)
        klass = Object.const_get(klass_name)
        raise PatchError, "already patched constant #{klass}" if patched?(klass)
        patched[klass] = {}
        class_methods_module = find_class_methods_module(klass_name)
        methods = class_methods_module && find_monkey_patch_class_methods(klass_name)
        # if methods&.delete(:new)
        #   patch_method!(klass, :new, class_methods_module.instance_method(:new))
        # else
        #   patch_method!(klass, :new, LightIO::Library::Base::ClassMethods.instance_method(:new))
        # end
        return unless class_methods_module && methods
        methods.each do |method_name|
          method = class_methods_module.instance_method(method_name)
          patch_method!(klass, method_name, method)
        end
      rescue
        patched.delete(klass)
        raise
      end

      def unpatch!(klass_name)
        klass = Object.const_get(klass_name)
        raise PatchError, "can't find patched constant #{klass}" unless patched?(klass)
        unpatch_method!(klass, :new)
        find_monkey_patch_class_methods(klass_name).each do |method_name|
          unpatch_method!(klass, method_name)
        end
        patched.delete(klass)
      end

      def find_class_methods_module(klass_name)
        LightIO::Module.const_get("#{klass_name}::ClassMethods", false)
      rescue NameError
        nil
      end

      def find_monkey_patch_class_methods(klass_name)
        find_class_methods_module(klass_name).instance_methods
      end

      def patched_method?(obj, method)
        patched?(obj) && patched[obj].key?(method)
      end

      def patched_methods(const)
        patched[const] ||= {}
      end

      def patch_method!(const, method, patched_method)
        raise PatchError, "already patched method #{const}.#{method}" if patched_method?(const, method)
        patched_methods(const)[method] = patched_method
        const.send(:define_singleton_method, method, patched_method)
        nil
      end

      def unpatch_method!(const, method)
        raise PatchError, "can't find patched method #{const}.#{method}" unless patched_method?(const, method)
        origin_method = patched[const].delete(method)
        const.send(:define_singleton_method, method, origin_method)
        nil
      end

      def patched
        @patched ||= {}
      end
    end
  end
end