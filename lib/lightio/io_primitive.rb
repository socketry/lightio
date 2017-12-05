module LightIO
  module IOPrimitive
    def wait_read(io, timeout=nil)
      io_watcher = Watchers::IO.new(io, :r)
      LightIO::IOloop.current.wait(io_watcher)
      io_watcher
    end

    def wait_write(io, timeout=nil)
      io_watcher = Watchers::IO.new(io, :w)
      LightIO::IOloop.current.wait(io_watcher)
      io_watcher
    end

    def wait_readwrite(io, timeout=nil)
      io_watcher = Watchers::IO.new(io, :rw)
      LightIO::IOloop.current.wait(io_watcher)
      io_watcher
    end
  end
end
