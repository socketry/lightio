require 'fiber'

module LightIO::Core
  # LightFiber is internal represent, we make slight extend on ruby Fiber to bind fibers to IOLoop
  #
  # SHOULD NOT BE USED DIRECTLY
  class LightFiber < Fiber
    attr_reader :ioloop
    attr_accessor :on_transfer

    ROOT_FIBER = Fiber.current

    def initialize(ioloop: IOloop.current, &blk)
      @ioloop = ioloop
      super(&blk)
    end

    def transfer
      on_transfer.call(LightFiber.current, self) if on_transfer
      super
    end

    class << self
      def is_root?(fiber)
        ROOT_FIBER == fiber
      end
    end
  end
end
