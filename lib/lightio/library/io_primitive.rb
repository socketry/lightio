module LightIO::Library
  module IOPrimitive
    def wait_read(io, timeout=nil)
      Timeout.timeout(timeout) do
        io_watcher = LightIO::Watchers::IO.new(io, :r)
        LightIO::IOloop.current.wait(io_watcher)
        io_watcher
      end
    rescue Timeout::Error
      nil
    end

    def wait_write(io, timeout=nil)
      Timeout.timeout(timeout) do
        io_watcher = LightIO::Watchers::IO.new(io, :w)
        LightIO::IOloop.current.wait(io_watcher)
        io_watcher
      end
    rescue Timeout::Error
      nil
    end

    def wait_readwrite(io, timeout=nil)
      Timeout.timeout(timeout) do
        io_watcher = LightIO::Watchers::IO.new(io, :rw)
        LightIO::IOloop.current.wait(io_watcher)
        io_watcher
      end
    rescue Timeout::Error
      nil
    end
  end
end