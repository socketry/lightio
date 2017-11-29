require 'fiber'

# Beam, a minimal executor unit, like thread but lightweight
# must have a ioloop
# new: create beam
# start: create and start a beam
# resume: switch beam to execute
module LightIO
  class Beam < Fiber
    def initialize ioloop:, &blk
      @ioloop = ioloop
      super(&blk)
    end
  end
end