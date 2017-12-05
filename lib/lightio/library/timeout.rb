require 'timeout'
module LightIO::Library
  module Timeout
    extend self
    Error = ::Timeout::Error

    def timeout(sec, klass=Error, &blk)
      return yield(sec) if sec.nil? or sec.zero?
      beam = LightIO::Beam.new(sec, &blk)
      message = "execution expired"
      if beam.join(sec).nil?
        raise klass, message
      else
        beam.value
      end
    end
  end
end