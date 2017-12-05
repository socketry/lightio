module LightIO
  module Watchers
    class IO < Watcher
      def initialize(io, interests)
        @io = io
        @interests = interests
      end

      def start(ioloop)
        ioloop.add_io_wait(@io, @interests, &callback)
      end

      def cancel_wait()
        ioloop.cancel_io_wait(@io)
      end
    end
  end
end