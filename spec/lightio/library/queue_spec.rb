require 'spec_helper'

RSpec.describe LightIO::Queue do
  describe "act as Queue" do
    it "#is_a?" do
      obj = LightIO::Library::Queue.new
      expect(obj).to be_a(LightIO::Library::Queue)
      expect(obj).to be_a(Queue)
      expect(obj).to be_kind_of(LightIO::Library::Queue)
      expect(obj).to be_kind_of(Queue)
    end

    it "#instance_of?" do
      obj = LightIO::Library::Queue.new
      expect(obj).to be_an_instance_of(LightIO::Library::Queue)
      expect(obj).to be_an_instance_of(Queue)
    end
  end

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