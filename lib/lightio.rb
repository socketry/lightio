require 'lightio/version'
require 'lightio/errors'
require 'lightio/light_fiber'
require 'lightio/future'
require 'lightio/ioloop'
require 'lightio/watcher'
require 'lightio/timer'
require 'lightio/backend/nio'
require 'lightio/beam'

module LightIO
  class << self
    # TODO handle sleep forever
    def sleep(duration)
      timer = LightIO::Timer.new duration
      LightIO::IOloop.current.wait(timer)
    end
  end
end
