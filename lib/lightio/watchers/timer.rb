module LightIO
  module Watchers
    class Timer < Watcher
      attr_reader :interval
      attr_accessor :uuid

      def initialize(interval)
        @interval = interval
      end

      def start(ioloop)
        ioloop.add_timer(self)
      end
    end
  end
end