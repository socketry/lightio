require 'spec_helper'

RSpec.describe LightIO::Timeout do
  describe "#timeout " do
    it "not reach timeout" do
      result = LightIO::Timeout.timeout(0.2) do
        1
      end
      expect(result).to be == 1
    end

    it "timeout" do
      expect do
        LightIO::Timeout.timeout(0.01) do
          LightIO.sleep 5
        end
      end.to raise_error LightIO::Timeout::Error
    end

    it "not timeout" do
      start = Time.now
      LightIO::Timeout.timeout(10) do
        1
      end
      expect(Time.now - start).to be < 1
    end

    it "timeout block operations" do
      start = Time.now
      expect {
        LightIO::Timeout.timeout(0.1) do
          LightIO.gets
        end
      }.to raise_error(Timeout::Error)
      expect(Time.now - start).to be < 1
    end
  end
end