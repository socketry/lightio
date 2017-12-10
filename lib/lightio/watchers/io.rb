module LightIO::Watchers
  # LightIO::Watchers::IO provide a NIO::Monitor wrap to manage 'raw' socket / io
  #
  # @Example:
  #   #- wait_read for server socket
  #   io_watcher = LightIO::Watchers::IO.new(server_socket, :r)
  #   loop do
  #     io_watcher.wait_read
  #     client_socket = server_socket.accept
  #     # do something
  #   end
  #   io_watcher.close
  class IO < Watcher
    # Create a io watcher
    # @param [Socket]  io An IO-able object
    # @param [Symbol]  interests :r, :w, :rw - Is io readable? writeable? or both
    # @return [LightIO::Watchers::IO]
    def initialize(io, interests)
      @io = io
      @ioloop = LightIO::Core::IOloop.current
      @waiting = false
      @wait_for = nil
      # NIO monitor
      @monitor = @ioloop.add_io_wait(@io, interests) {callback_on_waiting}
    end

    def interests
      @monitor.interests
    end

    # Replace current interests
    def interests=(interests)
      @monitor.interests = interests
    end

    # Blocking until io interests is satisfied
    def wait_for(interests)
      if (self.interests == :w || self.interests == :r) && interests != self.interests
        raise ArgumentError, "IO interests is #{self.interests}, can't waiting for #{interests}"
      end
      @wait_for = interests
      wait
    end

    # Blocking until io is readable
    # @param [Numeric]  timeout return nil after timeout seconds, otherwise return self
    # @return [LightIO::Watchers::IO, nil]
    def wait_read(timeout=nil)
      LightIO::Timeout.timeout(timeout) do
        wait_for :r
        self
      end
    rescue Timeout::Error
      nil
    end

    # Blocking until io is writeable
    # @param [Numeric]  timeout return nil after timeout seconds, otherwise return self
    # @return [LightIO::Watchers::IO, nil]
    def wait_write(timeout=nil)
      LightIO::Timeout.timeout(timeout) do
        wait_for :w
        self
      end
    rescue Timeout::Error
      nil
    end


    def start(ioloop)
      # do nothing
    end

    # stop io listening
    def close
      @monitor.close
    end

    def close?
      @monitor.close?
    end

    def wait
      raise LightIO::Error, "Watchers::IO can't cross threads" if @ioloop != LightIO::Core::IOloop.current
      raise EOFError, "can't wait closed IO watcher" if @monitor.closed?
      @waiting = true
      @ioloop.wait(self)
      @waiting = false
    end

    def set_callback(&blk)
      @callback = blk
    end

    private

    def callback_on_waiting
      # only call callback on waiting
      callback.call if @waiting && io_is_ready?
    end

    def io_is_ready?
      if @wait_for == :r
        @monitor.readable?
      elsif @wait_for == :w
        @monitor.writeable?
      end
    end
  end
end