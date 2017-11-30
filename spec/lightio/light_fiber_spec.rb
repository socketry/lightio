require 'spec_helper'

RSpec.describe LightIO::LightFiber do
  describe "#current " do
    it "can find current light fiber" do
      light_fiber = LightIO::LightFiber.new {
        LightIO::LightFiber.yield LightIO::LightFiber.current
      }
      expect(light_fiber.resume).to eq(light_fiber)
    end
  end
end