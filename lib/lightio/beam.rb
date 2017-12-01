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
        # TODO handle error
        begin
          @value = yield(*args)
        rescue StandardError => e
          @error = e
          raise
        end
      }
    end

    def value
      transfer if alive?
      raise @error if @error
      @value
    end


    def join(limit=0)
      if !alive? || limit <= 0
        value
        return self
      end

      LightIO.sleep limit
      check_back = Beam.current
      IOloop.current.add_timer(Timer.new(limit) {
        @error = TimeoutError.new
        check_back.transfer
      })
      # wait Ioloop
      value rescue TimeoutError
      alive? ? nil : self
    end
  end
end
