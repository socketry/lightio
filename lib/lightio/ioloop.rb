# IOloop like a per-threaded Eventmachine (cause fiber cannot resume cross threads)
# join, 等待 IOloop 结束
# 在 loop 中为 waiter (future-like proxy object) 对象返回结果
module LightIO
  class IOloop
    def initialize
      @fiber = Fiber.new {run}
      @backend = Backend::NIO.new
    end

    # should never invoke explicitly
    def run
      # start io loop and never return...
      @backend.run
    end

    # wait a watcher, maybe a timer or socket
    def wait(watcher)
      future = Future.new
      # add watcher to loop
      watcher.set_callback {future.transfer}
      watcher.register(@backend)
      # trigger a fiber switch
      # wait until watcher is ok
      # then do work
      future.value
    end

    def transfer
      @fiber.transfer
    end

    class << self
      # return current ioloop or create new one
      def current
        Thread.current[:"lightio.ioloop"] ||= IOloop.new
      end
    end
  end
end