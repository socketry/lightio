module LightIO
  module Monkey
    class PatchError < StandardError
    end

    IO_PATCH_CONSTANTS = %w{IO File Socket Socket::Ifaddr TCPServer TCPSocket BasicSocket Addrinfo IPSocket UDPSocket UNIXSocket UNIXServer OpenSSL::SSL::SSLSocket}.freeze
    THREAD_PATCH_CONSTANTS = %w{Thread ThreadGroup Queue SizedQueue ConditionVariable Mutex ThreadsWait}.freeze

    @patched

    class << self
      def patch_all!
        # Fix https://github.com/socketry/lightio/issues/7
        begin
          require 'ffi'
        rescue LoadError
          nil
        end

        patch_thread!
        patch_io!
        patch_kernel!
        nil
      end

      def unpatch_all!
        unpatch_thread!
        unpatch_io!
        unpatch_kernel!
        nil
      end

      def patched?(obj)
        patched.key?(obj) && !patched[obj]&.empty?
      end

      def patch_thread!
        require 'thread'
        THREAD_PATCH_CONSTANTS.each {|klass_name| patch!(klass_name)}
        patch_method!(Timeout, :timeout, LightIO::Timeout.method(:timeout))
        nil
      end

      def unpatch_thread!
        require 'thread'
        THREAD_PATCH_CONSTANTS.each {|klass_name| unpatch!(klass_name)}
        unpatch_method!(Timeout, :timeout)
        nil
      end

      def patch_io!
        require 'socket'
        IO_PATCH_CONSTANTS.each {|klass_name| patch!(klass_name)}
        patch_method!(Process, :spawn, LightIO.method(:spawn).to_proc)
        nil
      end

      def unpatch_io!
        require 'socket'
        IO_PATCH_CONSTANTS.each {|klass_name| unpatch!(klass_name)}
        unpatch_method!(Process, :spawn)
        nil
      end

      def patch_kernel!
        patch_kernel_method!(:sleep, LightIO.method(:sleep))
        patch_kernel_method!(:select, LightIO::Library::IO.method(:select))
        patch_kernel_method!(:open, LightIO::Library::File.method(:open).to_proc)
        patch_kernel_method!(:spawn, LightIO.method(:spawn).to_proc)
        patch_kernel_method!(:`, LightIO.method(:`).to_proc)
        patch_kernel_method!(:system, LightIO.method(:system).to_proc)
        %w{gets readline readlines}.each do |method|
          patch_kernel_method!(method.to_sym, LightIO.method(method.to_sym).to_proc)
        end
        nil
      end

      def unpatch_kernel!
        unpatch_kernel_method!(:sleep)
        unpatch_kernel_method!(:select)
        unpatch_kernel_method!(:open)
        unpatch_kernel_method!(:spawn)
        unpatch_kernel_method!(:`)
        unpatch_kernel_method!(:system)
        %w{gets readline readlines}.each do |method|
          unpatch_kernel_method!(method.to_sym, LightIO.method(method.to_sym).to_proc)
        end
        nil
      end

      private
      def patch!(klass_name)
        klass = Object.const_get(klass_name)
        raise PatchError, "already patched constant #{klass}" if patched?(klass)
        patched[klass] = {}
        class_methods_module = find_class_methods_module(klass_name)
        methods = class_methods_module && find_monkey_patch_class_methods(klass_name)
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

      def patch_kernel_method!(method_name, method)
        patch_method!(Kernel, method_name, method)
        patch_instance_method!(Kernel, method_name, method)
      end

      def unpatch_kernel_method!(method_name)
        unpatch_method!(Kernel, method_name)
        unpatch_instance_method!(Kernel, method_name)
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
        origin_method = patched_methods(const).delete(method)
        const.send(:define_singleton_method, method, origin_method)
        nil
      end

      def patched_instance_method?(obj, method)
        patched_instance_methods(obj).key?(method)
      end

      def patched_instance_methods(const)
        (patched[:instance_methods] ||= {})[const] ||= {}
      end

      def patch_instance_method!(const, method, patched_method)
        raise PatchError, "already patched method #{const}.#{method}" if patched_instance_method?(const, method)
        patched_instance_methods(const)[method] = patched_method
        const.send(:define_method, method, patched_method)
        nil
      end

      def unpatch_instance_method!(const, method)
        raise PatchError, "can't find patched method #{const}.#{method}" unless patched_instance_method?(const, method)
        origin_method = patched_instance_methods(const).delete(method)
        const.send(:define_method, method, origin_method)
        nil
      end

      def patched
        @patched ||= {}
      end
    end
  end
end