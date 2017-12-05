module LightIO
  module Watchers
    class Watcher
      attr_reader :callback

      def set_callback(&blk)
        raise Error, "already has callback" if @callback
        @callback = blk
      end

      def start(backend)
        raise
      end
    end
  end
end