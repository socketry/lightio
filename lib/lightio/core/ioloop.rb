require 'lightio/core/backend/nio'
require 'forwardable'

module LightIO::Core
  # IOloop like a per-threaded EventMachine (cause fiber cannot resume cross threads)
  #
  # IOloop handle io waiting and schedule beams, user do not supposed to directly use this class
  class IOloop

    RAW_THREAD = ::Thread

    def initialize
      @fiber = Fiber.new {run}
      @backend = Backend::NIO.new
    end

    extend Forwardable
    def_delegators :@backend, :run, :add_timer, :add_callback, :add_io_wait, :cancel_io_wait, :backend

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
      current_beam = LightIO::Core::Beam.current
      if response_id != id
        raise LightIO::InvalidTransferError, "expect #{id}, but get #{response_id}"
      elsif err
        # if future return a err
        # simulate Thread#raise to Beam , that we can shutdown beam blocking by socket accepting
        # transfer back to which beam occur this err
        # not sure this is a right way to do it
        current_beam.raise(err) if current_beam.is_a?(LightIO::Core::Beam)
      end
      # check beam error after wait
      current_beam.send(:check_and_raise_error) if current_beam.is_a?(LightIO::Core::Beam)
    end

    def transfer
      @fiber.transfer
    end

    class << self
      # return current ioloop or create new one
      def current
        key = :"lightio.ioloop"
        unless RAW_THREAD.current.thread_variable?(key)
          RAW_THREAD.current.thread_variable_set(key, IOloop.new)
        end
        RAW_THREAD.current.thread_variable_get(key)
      end
    end
  end
end