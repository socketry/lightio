require 'beam'

module LIO
  module Patch
    class << self
      def sleep(sec)
        fiber = Fiber.current
        EventMachine.add_timer(sec) {fiber.resume}
        Fiber.yield
      end

      def patch
        Kernel.send(:define_method, :sleep) {|*args| Patch.send(:sleep, *args)}
      end
    end
  end
end
