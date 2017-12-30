require_relative 'queue'

module LightIO::Library
  class SizedQueue < LightIO::Library::Queue
    attr_accessor :max

    def initialize(max)
      raise ArgumentError, 'queue size must be positive' unless max > 0
      super()
      @max = max
      @enqueue_waiters = []
    end

    def push(object)
      raise ClosedQueueError, "queue closed" if @close
      if size >= max
        future = LightIO::Future.new
        @enqueue_waiters << future
        future.value
      end
      super
      self
    end

    alias enq push
    alias << push

    def pop(non_block=false)
      result = super
      check_release_enqueue_waiter
      result
    end

    alias deq pop
    alias shift pop

    def clear
      result = super
      check_release_enqueue_waiter
      result
    end

    def max=(value)
      @max = value
      check_release_enqueue_waiter if size < max
    end

    def num_waiting
      super + @enqueue_waiters.size
    end

    private
    def check_release_enqueue_waiter
      if @enqueue_waiters.any?
        future = LightIO::Future.new
        LightIO::IOloop.current.add_callback {
          @enqueue_waiters.shift.transfer
          future.transfer
        }
        future.value
      end
    end
  end
end