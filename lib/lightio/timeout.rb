require 'timeout'
module LightIO
  module Timeout
    Error = TimeoutError
    class << self
      def timeout(sec, klass=Error, &blk)
        return yield(sec) if sec.nil? or sec.zero?
        beam = Beam.new(sec, &blk)
        message = "execution expired"
        if beam.join(sec).nil?
          raise klass, message
        else
          beam.value
        end
      end
    end
  end
end