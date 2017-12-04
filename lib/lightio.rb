require 'lightio/version'
require 'lightio/errors'
require 'lightio/light_fiber'
require 'lightio/future'
require 'lightio/ioloop'
require 'lightio/watchers'
require 'lightio/backend/nio'
require 'lightio/beam'

module LightIO
  class << self
    # TODO handle sleep forever
    def sleep(duration)
      if duration.zero? && Beam.current.respond_to?(:pass)
        Beam.current.pass
        return
      end
      timer = Watchers::Timer.new duration
      IOloop.current.wait(timer)
    end
  end
end
