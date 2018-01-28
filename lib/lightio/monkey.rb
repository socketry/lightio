module LightIO
  module Monkey
    class PatchError < StandardError
    end

    SOCKET_PATCH_CONSTANTS = %w{IO Socket TCPServer TCPSocket BasicSocket Addrinfo IPSocket UDPSocket UNIXSocket UNIXServer}.freeze
    THREAD_PATCH_CONSTANTS = %w{Thread ThreadGroup Queue SizedQueue ConditionVariable Mutex ThreadsWait Timeout}.freeze

    class << self
      def patch_all!
        patch_thread!
        patch_socket!
        patch_kernel!
      end

      def patched?(obj)
        obj < LightIO::Module::Base
      end

      def patch_thread!
        raise PatchError, "already patched constant #{Thread}" if patched?(Thread)
        require 'thread'

        Thread.prepend(LightIO::Module::Thread)
        ThreadGroup.prepend(LightIO::Module::ThreadGroup)
        Queue.prepend(LightIO::Module::Queue)
        SizedQueue.prepend(LightIO::Module::SizedQueue)
        ConditionVariable.prepend(LightIO::Module::ConditionVariable)
        Mutex.prepend(LightIO::Module::Mutex)
        ThreadsWait.prepend(LightIO::Module::ThreadsWait)
        patch_method!(Timeout, :timeout, LightIO::Timeout.method(:timeout))
      end

      def patch_socket!
        raise PatchError, "already patched constant #{IO}" if patched?(IO)
        require 'socket'

        IO.prepend(LightIO::Module::IO)
        BasicSocket.prepend(LightIO::Module::BasicSocket)
        Socket.prepend(LightIO::Module::Socket)
        IPSocket.prepend(LightIO::Module::IPSocket)
        TCPSocket.prepend(LightIO::Module::TCPSocket)
        TCPServer.prepend(LightIO::Module::TCPServer)
        UDPSocket.prepend(LightIO::Module::UDPSocket)
        UNIXSocket.prepend(LightIO::Module::UNIXSocket)
        UNIXServer.prepend(LightIO::Module::UNIXServer)
      end

      def patch_kernel!
        patch_method!(Kernel, :sleep, LightIO.method(:sleep))
        patch_method!(Kernel, :select, LightIO::Library::IO.method(:select))
      end

      private

      def patch_method!(const, method, patched_method)
        patched = const.method(method) == patched_method
        raise PatchError, "already patched method #{const}.#{method}" if patched
        const.send(:define_method, method, &patched_method)
        nil
      end
    end
  end
end