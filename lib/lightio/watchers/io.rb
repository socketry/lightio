require 'forwardable'

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
    def initialize(io, interests=:rw)
      @io = io
      @ioloop = LightIO::Core::IOloop.current
      @waiting = false
      ObjectSpace.define_finalizer(self, self.class.finalizer(@monitor))
      @error = nil
    end

    # NIO::Monitor
    def monitor(interests=:rw)
      @monitor ||= begin
        @ioloop.add_io_wait(@io, interests) {callback_on_waiting}
      end
    end

    class << self
      def finalizer(monitor)
        proc {monitor.close if monitor && !monitor.close?}
      end
    end

    extend Forwardable
    def_delegators :monitor, :interests, :interests=, :closed?

    def readable?
      check_monitor_read
      monitor.readable?
    end

    def writable?
      check_monitor_write
      monitor.writable?
    end

    alias :writeable? :writable?

    # Blocking until io is readable
    # @param [Numeric]  timeout return nil after timeout seconds, otherwise return self
    # @return [LightIO::Watchers::IO, nil]
    def wait_readable(timeout=nil)
      wait timeout, :read
    end

    # Blocking until io is writable
    # @param [Numeric]  timeout return nil after timeout seconds, otherwise return self
    # @return [LightIO::Watchers::IO, nil]
    def wait_writable(timeout=nil)
      wait timeout, :write
    end

    def wait(timeout=nil, mode=:read)
      LightIO::Timeout.timeout(timeout) do
        check_monitor(mode)
        in_waiting(mode) do
          wait_in_ioloop
        end
        self
      end
    rescue Timeout::Error
      nil
    end

    def close
      return if closed?
      monitor.close
      @error = IOError.new('closed stream')
      callback_on_waiting
    end


    # just implement IOloop#wait watcher interface
    def start(ioloop)
      # do nothing
    end

    def set_callback(&blk)
      @callback = blk
    end

    private
    def check_monitor(mode)
      case mode
        when :read
          check_monitor_read
        when :write
          check_monitor_write
        when :read_write
          check_monitor_read_write
        else
          raise ArgumentError, "get unknown value #{mode}"
      end
    end

    def check_monitor_read
      if monitor(:r).interests == :w
        monitor.interests = :rw
      end
    end

    def check_monitor_write
      if monitor(:w).interests == :r
        monitor.interests = :rw
      end
    end

    def check_monitor_read_write
      if monitor(:rw).interests != :rw
        monitor.interests = :rw
      end
    end

    # Blocking until io interests is satisfied
    def wait_in_ioloop
      raise LightIO::Error, "Watchers::IO can't cross threads" if @ioloop != LightIO::Core::IOloop.current
      raise EOFError, "can't wait closed IO watcher" if @monitor.closed?
      @ioloop.wait(self)
    end

    def in_waiting(mode)
      @waiting = mode
      yield
      @waiting = false
    end

    def callback_on_waiting
      # only call callback on waiting
      return unless io_is_ready?
      if @error
        # if error occurred in io waiting, send it to callback, see IOloop#wait
        callback&.call(LightIO::Core::Beam::BeamError.new(@error))
      else
        callback&.call
      end
    end

    def io_is_ready?
      return false unless @waiting
      return true if closed?
      if @waiting == :r
        readable?
      elsif @waiting == :w
        writable?
      else
        readable? || writable?
      end
    end
  end
end