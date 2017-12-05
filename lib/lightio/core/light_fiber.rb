require 'fiber'

module LightIO::Core
  # LightFiber is internal represent, we make slight extend on ruby Fiber to bind fibers to IOLoop
  #
  # SHOULD NOT BE USED DIRECTLY
  class LightFiber < Fiber
    attr_reader :ioloop

    def initialize(ioloop: IOloop.current, &blk)
      @ioloop = ioloop
      super(&blk)
    end
  end
end
