require 'open3'
module LightIO::Library
  module KernelExt
    KERNEL_PROXY = ::LightIO::RawProxy.new(::Kernel,
                                           methods: [:spawn, :`])

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

    def `(cmd)
      Open3.popen3(cmd, out: STDOUT, err: STDERR) do |stdin, stdout, stderr, wait_thr|
        output = LightIO::Library::IO._wrap(stdout).read
        KERNEL_PROXY.send(:`, "exit #{wait_thr.value.exitstatus}")
        return output
      end
    end

    def system(*cmd, **opt)
      Open3.popen3(*cmd, **opt) do |stdin, stdout, stderr, wait_thr|
        return nil if LightIO::Library::IO._wrap(stderr).read.size > 0
        return wait_thr.value.exitstatus == 0
      end
    rescue Errno::ENOENT
      nil
    end

    private
    def convert_io_or_array_to_raw(io_or_array)
      if io_or_array.is_a?(LightIO::Library::IO)
        io_or_array.send(:light_io_raw_obj)
      elsif io_or_array.is_a?(Array)
        io_or_array.map {|io| convert_io_or_array_to_raw(io)}
      end
    end
  end
end