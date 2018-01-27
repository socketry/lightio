module LightIO
  module Monkey
    class PatchError < StandardError
    end

    SOCKET_PATCH_CONSTANTS = %w{IO Socket TCPServer TCPSocket BasicSocket Addrinfo IPSocket UDPSocket UNIXSocket UNIXServer}.freeze
    THREAD_PATCH_CONSTANTS = %w{Thread ThreadGroup Queue SizedQueue ConditionVariable Mutex ThreadsWait Timeout}.freeze

    class << self
      def patch_all!(silence: true)
        patch_thread!(silence: silence)
        patch_socket!(silence: silence)
        patch_kernel!(silence: silence)
      end

      def unpatch_all!(silence: true)
        unpatch_thread!(silence: silence)
        unpatch_socket!(silence: silence)
        unpatch_kernel!(silence: silence)
      end

      def patched?(obj)
        patched.has_key?(obj)
      end

      def get_origin(obj)
        patched[obj]
      end

      def patch_thread!(silence: true)
        silence_warning(silence: silence) do
          THREAD_PATCH_CONSTANTS.each {|c| patch!(c)}
        end
      end

      def unpatch_thread!(silence: true)
        silence_warning(silence: silence) do
          THREAD_PATCH_CONSTANTS.reverse.each {|c| unpatch!(c)}
        end
      end

      def patch_socket!(silence: true)
        silence_warning(silence: silence) do
          SOCKET_PATCH_CONSTANTS.each {|c| patch!(c)}
        end
      end

      def unpatch_socket!(silence: true)
        silence_warning(silence: silence) do
          SOCKET_PATCH_CONSTANTS.reverse.each {|c| unpatch!(c)}
        end
      end

      def patch_kernel!(silence: true)
        silence_warning(silence: silence) do
          patch_method!(Kernel, :sleep, LightIO.method(:sleep))
          patch_method!(Kernel, :select, LightIO::Library::IO.method(:select))
        end
      end

      def unpatch_kernel!(silence: true)
        silence_warning(silence: silence) do
          unpatch_method!(Kernel, :sleep)
          unpatch_method!(Kernel, :select)
        end
      end

      private
      def patch!(const_or_name)
        const_name = const_or_name.to_s
        const = Object.const_get(const_name)
        raise PatchError, "already patched constant #{const}" if patched?(const)
        patched_const = LightIO.const_get(const_name)
        patched[patched_const] = const
        const_set(const_name, patched_const)
        nil
      end

      def unpatch!(const_or_name)
        const_name = const_or_name.to_s
        const = Object.const_get(const_name)
        raise PatchError, "unknown constant #{const}" unless patched?(const)
        origin_const = patched[const]
        const_set(const_name, origin_const)
        patched.delete(const)
        nil
      end

      def silence_warning(silence: true)
        verbose = $VERBOSE
        $VERBOSE = nil if silence
        yield
      ensure
        $VERBOSE = verbose
      end


      def const_set(name, obj)
        # find namespace, Thread::Queue
        i = name.rindex('::')
        namespace = i ? Object.const_get(name[0...i]) : Object
        const_module = i ? name[(i + 2)..-1] : name
        namespace.const_set(const_module, obj)
      end

      def patch_method!(const, method, patched_method)
        key = [const, method]
        raise PatchError, "already patched method #{const}.#{method}" if patched?(key)
        # save method
        patched[key] = const.method(method)
        const.send(:define_method, method, &patched_method)
        nil
      end

      def unpatch_method!(const, method)
        key = [const, method]
        raise PatchError, "unknown method #{const}.#{method}" unless patched?(key)
        origin_method = patched[key]
        const.send(:define_method, method, &origin_method)
        patched.delete(key)
        nil
      end

      def patched
        @patched ||= {}
      end
    end
  end
end