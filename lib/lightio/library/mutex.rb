require_relative 'queue'

module LightIO::Library
  class Mutex
    def initialize
      @queue = Queue.new
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
end
