module LightIO::Library
  module KernelExt
    def sleep(*duration)
      if duration.size > 1
        raise ArgumentError, "wrong number of arguments (given #{duration.size}, expected 0..1)"
      elsif duration.size == 0
        LightIO::IOloop.current.transfer
      end
      duration = duration[0]
      if duration.zero? && LightIO::Beam.current.respond_to?(:pass)
        LightIO::Beam.current.pass
        return
      end
      timer = LightIO::Watchers::Timer.new duration
      LightIO::IOloop.current.wait(timer)
    end
  end
end