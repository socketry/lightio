RSpec.describe Lightio do
  it "has a version number" do
    expect(Lightio::VERSION).not_to be nil
  end

  describe "#sleep" do
    it "sleep work" do
      t1 = Time.now
      duration = 0.1
      LightIO.sleep duration
      expect(Time.now - t1).to be > duration
    end

    it "can sleep zero time" do
      t1 = Time.now
      duration = 0.1
      LightIO.sleep 0
      expect(Time.now - t1).to be < duration
    end

    it "sleep forever" do
      expect {LightIO.timeout(0.1) do
        LightIO.sleep
      end}.to raise_error LightIO::TimeoutError
    end
  end
end
