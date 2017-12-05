module LightIO
  module KernelExt
    def sleep(*duration)
      if duration.size > 1
        raise ArgumentError, "wrong number of arguments (given #{duration.size}, expected 0..1)"
      elsif duration.size == 0
        IOloop.current.transfer
      end
      duration = duration[0]
      if duration.zero? && Beam.current.respond_to?(:pass)
        Beam.current.pass
        return
      end
      timer = Watchers::Timer.new duration
      IOloop.current.wait(timer)
    end
  end
end