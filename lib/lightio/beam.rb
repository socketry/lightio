# A light-weight executor unit
# Example:
# - initialize with block, beam will start execute it just like Thread
# Beam.new{puts "hello"}
# output: hello
# Beam.new(1,2,3){|one, two, three| puts [one, two, three].join(",") }
# output: 1,2,3
# - use join wait beam done
# b = Beam.new(){LightIO.sleep 3}
# b.join
# b.alive?
# output: false
module LightIO
  class Beam < LightFiber
    def initialize(*args, &blk)
      raise Error, "must be called with a block" unless blk
      super() {
        begin
          @value = yield(*args)
        rescue StandardError => e
          @error = e
        end
        # transfer back to parent(caller fiber) after schedule
        parent.transfer
      }
      # schedule beam in ioloop
      ioloop.add_callback {transfer}
    end

    def value
      if alive?
        self.parent = Beam.current
        ioloop.transfer
      end
      check_and_raise_error
      @value
    end


    def join(limit=0)
      # try directly get result
      if !alive? || limit <= 0
        # call value to raise error
        value
        return self
      end

      self.parent = Beam.current
      LightIO.sleep limit
      if alive?
        nil
      else
        check_and_raise_error
        self
      end
    end

    private

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
