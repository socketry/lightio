require 'lightio/core/backend/nio'
module LightIO::Core
  # IOloop like a per-threaded EventMachine (cause fiber cannot resume cross threads)
  #
  # IOloop handle io waiting and schedule beams, user do not supposed to directly use this class
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

    def add_io_wait(io, interests, &blk)
      @backend.add_io_wait(io, interests, &blk)
    end

    def cancel_io_wait(io)
      @backend.cancel_io_wait(io)
    end

    # Wait a watcher, watcher can be a timer or socket.
    # see LightIO::Watchers module for detail
    def wait(watcher)
      future = Future.new
      # add watcher to loop
      id = Object.new
      watcher.set_callback {|err| future.transfer([id, err])}
      watcher.start(self)
      # trigger a fiber switch
      # wait until watcher is ok
      # then do work
      response_id, err = future.value
      if response_id != id
        raise InvalidTransferError, "expect #{id}, but get #{result}"
      elsif err
        # if future return a err
        # simulate Thread#raise to Beam , that we can shutdown beam blocking by socket accepting
        # transfer back to which beam occur this err
        # not sure this is a right way to do it
        LightIO::Core::Beam.current.raise(err)
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