module LightIO
  class Timer < Watcher
    attr_reader :interval
    attr_accessor :uuid

    def initialize(interval, &blk)
      @interval = interval
      @callback = blk
    end

    def register(backend)
      backend.add_timer(self)
    end
  end
end