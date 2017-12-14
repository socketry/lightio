require 'spec_helper'

RSpec.describe LightIO::Queue do
  describe "queue " do
    it "works" do
      q = LightIO::Queue.new
      b = LightIO::Beam.new {q.pop}
      b.join(0.01)
      expect(q.num_waiting).to be == 1
      q << "yes"
      expect(b.value).to be == "yes"
    end

    it "works with beams" do
      q = LightIO::Queue.new
      beams = 3.times.map {LightIO::Beam.new {q.pop}}
      beams.each {|b| b.join(0.01)}
      expect(q.num_waiting).to be == 3
      q << "one"
      q << "two"
      q << "three"
      expect(beams.map(&:value)).to be == ["one", "two", "three"]
    end

    it 'push and pop' do
      q = LightIO::Queue.new
      q << 4
      expect(q.pop).to be == 4
    end
  end
end