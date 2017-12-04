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

  describe "#pass" do
    it 'works' do
      result = []
      b1 = LightIO::Beam.new {result << 1; LightIO::Beam.pass; result << 3}
      b2 = LightIO::Beam.new {result << 2; LightIO::Beam.pass; result << 4}
      b1.join; b2.join
      expect(result).to eq([1, 2, 3, 4])
    end

    it "call from non beam" do
      expect(LightIO::Beam.pass).to be_nil
    end
  end

  describe "#alive?" do
    it "works" do
      beam = LightIO::Beam.new {1 + 2}
      expect(beam.alive?).to be_truthy
      beam.value
      expect(beam.alive?).to be_falsey
    end

    it "dead if error raised" do
      beam = LightIO::Beam.new {1 / 0}
      expect(beam.alive?).to be_truthy
      expect {beam.value}.to raise_error ZeroDivisionError
      expect(beam.alive?).to be_falsey
    end
  end

  describe "#kill" do
    it 'works' do
      beam = LightIO::Beam.new{1 + 2}
      expect(beam.alive?).to be_truthy
      expect(beam.kill).to be beam
      expect(beam.alive?).to be_falsey
      expect(beam.value).to be_nil
    end

    it 'kill self' do
      result = []
      beam = LightIO::Beam.new{result << 1;LightIO::Beam.current.kill;result << 2}
      expect(beam.alive?).to be_truthy
      beam.join
      expect(beam.alive?).to be_falsey
      expect(beam.value).to be_nil
      expect(result).to be == [1]
    end
  end

  describe "concurrent" do
    it "should concurrent schedule" do
      t1 = Time.now
      beams = 20.times.map {LightIO::Beam.new {LightIO.sleep 0.1}}
      beams.each {|b| b.join}
      expect(Time.now - t1).to be < 2
    end
  end
end
