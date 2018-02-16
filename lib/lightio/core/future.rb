module LightIO::Core
  # Provide a safe way to transfer beam/fiber control flow.
  #
  # @Example:
  #   future = Future.new
  #   # future#value will block current beam
  #   Beam.new{future.value}
  #   # use transfer to set value
  #   future.transfer(1)
  class Future
    def initialize
      @value = nil
      @ioloop = IOloop.current
      @state = :init
      @light_fiber = nil
    end

    def done?
      @state == :done
    end

    # Transfer and set result value
    #
    # use this method to set back result
    def transfer(value=nil)
      raise LightIO::Error, "state error" if done?
      @value = value
      done!
      @light_fiber.transfer if @light_fiber
    end

    def value=(value)
      transfer(value)
    end

    # Get value
    #
    # this method will block current beam/fiber, until future result is set.
    def value
      return @value if done?
      raise LightIO::Error, 'already used' if @light_fiber
      @light_fiber = LightFiber.current
      @ioloop.transfer
      @value
    end

    private

    def done!
      @state = :done
    end
  end
end