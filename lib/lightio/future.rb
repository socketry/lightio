# Future, provide another way to operate LightFiber and Ioloop

module LightIO
  class Future
    def initialize
      @value = nil
      @ioloop = IOloop.current
      @state = :init
    end

    def done?
      @state == :done
    end

    def done!
      @state = :done
    end

    # transfer and set value
    def transfer(value=nil)
      raise Error, "state error" if done?
      @value = value
      done!
      @light_fiber.transfer if @light_fiber
    end

    # block current fiber and get value
    def value
      return @value if done?
      @light_fiber = LightFiber.current
      @ioloop.transfer
      @value
    end
  end
end