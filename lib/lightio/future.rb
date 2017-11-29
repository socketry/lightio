# Future, provide another way to operate Beam and Ioloop

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
      @beam.transfer if @beam
    end

    # block current beam/fiber and get value
    def value
      return @value if done?
      @beam = Beam.current
      @ioloop.transfer
      @value
    end
  end
end