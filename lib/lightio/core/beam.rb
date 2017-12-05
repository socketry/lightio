module LightIO::Core
  # Beam is light-weight executor, provide thread-like interface
  #
  # @Example:
  #   #- initialize with block
  #   b = Beam.new{puts "hello"}
  #   b.join
  #   #output: hello
  #
  #   b = Beam.new(1,2,3){|one, two, three| puts [one, two, three].join(",") }
  #   b.join
  #   #output: 1,2,3
  #
  #   #- use join wait beam done
  #   b = Beam.new(){LightIO.sleep 3}
  #   b.join
  #   b.alive? # false
  class Beam < LightFiber

    # Create a new beam
    #
    # Beam is light-weight executor, provide thread-like interface
    #
    # Beam.new("hello"){|hello| puts hello }
    #
    # @param [Array]  args pass arguments to Beam block
    # @param [Proc]  blk block to execute
    # @return [Beam]
    def initialize(*args, &blk)
      raise Error, "must be called with a block" unless blk
      super() {
        begin
          @value = yield(*args)
        rescue StandardError => e
          @error = e
        end
        # mark as dead
        dead
        # transfer back to parent(caller fiber) after schedule
        parent.transfer
      }
      # schedule beam in ioloop
      ioloop.add_callback {transfer}
      @alive = true
    end

    def alive?
      super && @alive
    end

    # block and wait beam return a value
    def value
      if alive?
        self.parent = Beam.current
        ioloop.transfer
      end
      check_and_raise_error
      @value
    end

    # Block and wait beam dead
    #
    # @param [Numeric]  limit wait limit seconds if limit > 0, return nil if beam still alive, else return beam self
    # @return [Beam, nil]
    def join(limit=0)
      # try directly get result
      if !alive? || limit <= 0
        # call value to raise error
        value
        return self
      end

      # set a transfer back timer
      parent = Beam.current
      timer = LightIO::Watchers::Timer.new(limit)
      timer.set_callback {parent.transfer}
      ioloop.add_timer(timer)
      ioloop.transfer

      if alive?
        nil
      else
        check_and_raise_error
        self
      end
    end

    # Kill beam
    #
    # @return [Beam]
    def kill
      dead
      parent.transfer if self == Beam.current
      self
    end

    class << self

      # Schedule beams
      #
      # normally beam should be auto scheduled, use this method to manually trigger a schedule
      #
      # @return [nil]
      def pass
        schedule = LightIO::Watchers::Schedule.new
        IOloop.current.wait(schedule)
      end
    end

    private

    # mark beam as dead
    def dead
      @alive = false
    end

    # Beam transfer back to parent after schedule
    # parent is fiber or beam who called value/join methods
    # if not present a parent, Beam will transfer to ioloop
    def parent=(parent)
      @parent = parent
    end

    # get parent/ioloop to transfer back
    def parent
      @parent || ioloop
    end

    def check_and_raise_error
      raise @error if @error
    end
  end
end
