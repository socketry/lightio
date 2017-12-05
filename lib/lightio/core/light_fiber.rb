require 'fiber'

# LightFiber is internal represent SHOULD NOT BE USED DIRECTLY
# make a little bit extend to fiber
module LightIO::Core
  class LightFiber < Fiber
    attr_reader :ioloop

    def initialize(ioloop: IOloop.current, &blk)
      @ioloop = ioloop
      super(&blk)
    end
  end
end
