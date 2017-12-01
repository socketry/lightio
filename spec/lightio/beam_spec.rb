require 'spec_helper'

RSpec.describe LightIO::Beam do
  describe "#initialize" do
    it "should not execute" do
      expect(LightIO::Beam.new {1 / 0}).not_to be_nil
    end
  end

  describe "#value" do
    it "get value" do
      expect(LightIO::Beam.new {1 + 2}.value).to be 3
    end

    it "pass arguments" do
      expect(LightIO::Beam.new(1, 2) {|one, two| one + two}.value).to be 3
    end

    it "raise error" do
      expect {LightIO::Beam.new {1 / 0}.value}.to raise_error ZeroDivisionError
    end
  end

  describe "#join" do
    it "work well" do
      t = nil
      beam = LightIO::Beam.new {t = true}
      expect(t).to be_nil
      beam.join
      expect(t).to be true
    end

    it "with a limit time" do
      t1 = Time.now
      duration = 10
      expect(LightIO::Beam.new {LightIO.sleep(duration)}.join(0.1)).to be_nil
      expect(Time.now - t1).to be < duration
    end
  end

  describe "concurrent" do
    it "should concurrent schedule" do
      t1 = Time.now
      beams = 10.times.map {LightIO::Beam.new {LightIO.sleep 1}}
      beams.each {|b| b.join}
      expect(Time.now - t1).to be < 2
    end
  end
end
