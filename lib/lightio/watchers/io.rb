module LightIO
  module Watchers
    class IO < Watcher
      def initialize(io, interests)
        @io = io
        @interests = interests
        @ioloop = nil
      end

      def start(ioloop)
        @ioloop = ioloop
        ioloop.add_io_wait(@io, @interests, &callback)
      end

      def cancel_wait()
        raise LightIO::Error, "not attached to ioloop" unless @ioloop
        @ioloop.cancel_io_wait(@io)
      end
    end
  end
end