module LightIO
  module Watchers
    class Callback < Watcher
      def start(ioloop)
        ioloop.add_callback(&@callback)
      end
    end
  end
end