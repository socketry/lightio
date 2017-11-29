require 'spec_helper'

RSpec.describe LightIO::Beam do
  describe "#current " do
    it "can find current beam" do
      fake_ioloop = Object.new
      beam = LightIO::Beam.new(ioloop: fake_ioloop) {
        LightIO::Beam.yield LightIO::Beam.current
      }
      expect(beam.resume).to eq(beam)
    end
  end
end