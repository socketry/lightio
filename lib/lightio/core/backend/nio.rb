# use nio4r implement event loop, inspired from eventmachine/pure_ruby implement
require 'nio'
require 'set'
module LightIO::Core
  module Backend

    class Error < RuntimeError
    end

    class UnknownTimer < Error
    end

    class Timers
      def generate_uuid
        @ix ||= 0
        @ix += 1
      end

      def initialize
        @timers = SortedSet.new
        @timers_registry = {}
      end

      def add_timer(timer)
        uuid = generate_uuid
        @timers.add([Time.now + timer.interval, uuid])
        @timers_registry[uuid] = timer.callback
      end

      def cancel_timer(timer)
        raise Error, "unregistered timer" unless timer.uuid && @timers_registry.has_key?(timer.uuid)
        @timers_registry[uuid] = false
      end

      def fire(current_loop_time)
        @timers.each do |t|
          if t.first <= current_loop_time
            @timers.delete(t)
            callback = @timers_registry.delete(t.last)
            next if callback == false # timer cancelled
            raise UnknownTimer, "timer id: #{t.last}" if callback.nil?
            callback.call
          else
            break
          end
        end
      end
    end

    # LightIO use NIO as default event-driving backend
    class NIO
      def initialize
        # @selector = NIO::Selector.new
        @current_loop_time = nil
        @running = false
        @timers = Timers.new
        @callbacks = []
        @selector = ::NIO::Selector.new
      end

      def run
        raise Error, "already running" if @running
        @running = true
        loop do
          @current_loop_time = Time.now
          run_timers
          run_callbacks
          handle_selectables
        end
      end


      def add_callback(&blk)
        @callbacks << blk
      end

      def add_timer(timer)
        timer.uuid = @timers.add_timer(timer)
      end

      def cancel_timer(timer)
        @timers.cancel_timer(timer)
      end

      def add_io_wait(io, interests, &blk)
        monitor = @selector.register(io, interests)
        monitor.value = blk
        monitor
      end

      def cancel_io_wait(io)
        @selector.deregister(io)
      end

      def stop
        return unless @running
        @running = false
        raise
      end

      private

      def run_timers
        @timers.fire(@current_loop_time)
      end

      def handle_selectables
        @selector.select(0) do |monitor|
          # invoke callback if io is ready
          monitor.value.call(monitor.io)
        end
      end

      def run_callbacks
        while (callback = @callbacks.shift)
          callback.call
        end
      end
    end
  end
end