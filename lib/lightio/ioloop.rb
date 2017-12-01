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

    def add_timer(timer)
      @backend.add_timer(timer)
    end

    def add_callback(&blk)
      @backend.add_callback(&blk)
    end

    # wait a watcher, maybe a timer or socket
    def wait(watcher)
      future = Future.new
      # add watcher to loop
      id = Object.new
      watcher.set_callback {future.transfer id}
      watcher.start(self)
      # trigger a fiber switch
      # wait until watcher is ok
      # then do work
      if (result = future.value) != id
        raise InvalidTransferError, "expect #{id}, but get #{result}"
      end
    end

    def transfer
      @fiber.transfer
    end

    class << self
      # return current ioloop or create new one
      def current
        key = :"lightio.ioloop"
        unless Thread.current.thread_variable?(key)
          Thread.current.thread_variable_set(key, IOloop.new)
        end
        Thread.current.thread_variable_get(key)
      end
    end
  end
end