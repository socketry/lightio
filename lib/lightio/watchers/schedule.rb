module LightIO
  module Watchers
    class Schedule < Watcher
      def start(ioloop)
        ioloop.add_callback(&@callback)
      end
    end
  end
end