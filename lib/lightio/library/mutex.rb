require_relative 'queue'

module LightIO::Library
  class Thread
    class Mutex
      def initialize
        @queue = LightIO::Library::Queue.new
        @queue << true
        @locked_thread = nil
      end

      def lock
        raise ThreadError, "deadlock; recursive locking" if owner?
        @queue.pop
        @locked_thread = LightIO::Thread.current
        self
      end

      def unlock
        raise ThreadError, "Attempt to unlock a mutex which is not locked" unless owner?
        @locked_thread = nil
        @queue << true
        self
      end

      def locked?
        !@locked_thread.nil?
      end

      def owner?
        @locked_thread == LightIO::Thread.current
      end

      def sleep(timeout=nil)
        unlock
        LightIO.sleep(timeout)
        lock
      end

      def synchronize
        raise ThreadError, 'must be called with a block' unless block_given?
        lock
        begin
          yield
        ensure
          unlock
        end
      end

      def try_lock
        if @locked_thread.nil?
          lock
          true
        else
          false
        end
      end
    end

    class ConditionVariable
      def initialize
        @queue = LightIO::Library::Queue.new
      end


      def broadcast
        signal until @queue.num_waiting == 0
        self
      end

      def signal
        @queue << true unless @queue.num_waiting == 0
        self
      end

      def wait(mutex, timeout=nil)
        mutex.unlock
        begin
          LightIO::Library::Timeout.timeout(timeout) do
            @queue.pop
          end
        rescue Timeout::Error
          nil
        end
        mutex.lock
        self
      end
    end
  end

  Mutex = Thread::Mutex
  ConditionVariable = Thread::ConditionVariable
end
