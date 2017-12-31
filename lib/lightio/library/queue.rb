module LightIO::Library
  class Queue
    def initialize
      @queue = []
      @waiters = []
      @close = false
    end

    def close()
      #This is a stub, used for indexing
      @close = true
      @waiters.each {|w| w.transfer nil}
      self
    end

    # closed?
    #
    # Returns +true+ if the queue is closed.
    def closed?()
      @close
    end

    # push(object)
    # enq(object)
    # <<(object)
    #
    # Pushes the given +object+ to the queue.
    def push(object)
      raise ClosedQueueError, "queue closed" if @close
      if (waiter = @waiters.shift)
        future = LightIO::Future.new
        LightIO::IOloop.current.add_callback {
          waiter.transfer(object)
          future.transfer
        }
        future.value
      else
        @queue << object
      end
      self
    end

    alias enq push
    alias << push
    # pop(non_block=false)
    # deq(non_block=false)
    # shift(non_block=false)
    #
    # Retrieves data from the queue.
    #
    # If the queue is empty, the calling thread is suspended until data is pushed
    # onto the queue. If +non_block+ is true, the thread isn't suspended, and an
    # exception is raised.
    def pop(non_block=false)
      if @close
        return empty? ? nil : @queue.pop
      end
      if empty?
        if non_block
          raise ThreadError, 'queue empty'
        else
          future = LightIO::Future.new
          @waiters << future
          future.value
        end
      else
        @queue.pop
      end
    end

    alias deq pop
    alias shift pop
    # empty?
    #
    # Returns +true+ if the queue is empty.
    def empty?()
      @queue.empty?
    end

    # Removes all objects from the queue.
    def clear()
      @queue.clear
      self
    end

    # length
    # size
    #
    # Returns the length of the queue.
    def length()
      @queue.size
    end

    alias size length
    # Returns the number of threads waiting on the queue.
    def num_waiting()
      @waiters.size
    end
  end
end