# use nio4r implement event loop, inspired from eventmachine/pure_ruby implement
require 'set'
module LightIO
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

    class NIO
      def initialize
        # @selector = NIO::Selector.new
        @current_loop_time = nil
        @running = false
        @timers = Timers.new
        @callbacks = []
      end

      def run
        raise Error, "already running" if @running
        @running = true
        loop do
          @current_loop_time = Time.now
          run_timers
          run_callbacks
        end
      end

      def run_callbacks
        while (callback = @callbacks.shift)
          callback.call
        end
      end

      def add_callback(&blk)
        @callbacks << blk
      end

      def run_timers
        @timers.fire(@current_loop_time)
      end

      def add_timer(timer)
        timer.uuid = @timers.add_timer(timer)
      end

      def cancel_timer(timer)
        @timers.cancel_timer(timer)
      end

      def stop
        return unless @running
        @running = false
        raise
      end
    end
  end
end