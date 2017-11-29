require 'fiber'

# Beam, a minimal executor unit, like thread but lightweight
# must have a ioloop
module LightIO
  class Beam < Fiber
    def initialize ioloop:, &blk
      @ioloop = ioloop
      super(&blk)
    end
  end
end