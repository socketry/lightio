module LightIO::Library
  module KernelExt
    KERNEL_PROXY = ::LightIO::RawProxy.new(::Kernel,
                                           methods: [:spawn])

    def sleep(*duration)
      if duration.size > 1
        raise ArgumentError, "wrong number of arguments (given #{duration.size}, expected 0..1)"
      elsif duration.size == 0
        LightIO::IOloop.current.transfer
      end
      duration = duration[0]
      if duration.zero?
        LightIO::Beam.pass
        return
      end
      timer = LightIO::Watchers::Timer.new duration
      LightIO::IOloop.current.wait(timer)
    end

    def spawn(*commands, **options)
      options = options.dup
      options.each do |key, v|
        if key.is_a?(LightIO::Library::IO)
          options.delete(key)
          key = convert_io_or_array_to_raw(key)
          options[key] = v
        end
        if (io = convert_io_or_array_to_raw(v))
          options[key] = io
        end
      end
      KERNEL_PROXY.send(:spawn, *commands, **options)
    end

    private
    def convert_io_or_array_to_raw(io_or_array)
      if io_or_array.is_a?(LightIO::Library::IO)
        io_or_array.instance_variable_get(:@obj)
      elsif io_or_array.is_a?(Array)
        io_or_array.map {|io| convert_io_or_array_to_raw(io)}
      end
    end
  end
end