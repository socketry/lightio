# IOloop like a per-threaded Eventmachine (cause fiber cannot resume cross threads)
# join, 等待 IOloop 结束
# 在 loop 中为 waiter (future-like proxy object) 对象返回结果
module LightIO
  class IOloop
    def initialize
      @fiber = Fiber.new {run}
    end

    # should never invoke explicitly
    def run
      # start io loop and never return...
    end

    # wait a watcher, maybe a timer or socket
    def wait(watcher)
      # add watcher to loop
      # trigger a fiber switch
      # wait until watcher is ok
      # then do work
    end

    def resume
      @fiber.resume
    end

    class << self
      # return current ioloop or create new one
      def current
        Thread.current[:"lightio.ioloop"] ||= IOloop.new
      end
    end
  end
end