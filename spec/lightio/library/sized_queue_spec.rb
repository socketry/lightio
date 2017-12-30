require 'spec_helper'

RSpec.describe LightIO::SizedQueue do
  describe "#new" do
    it "max must > 0" do
      expect {LightIO::SizedQueue.new(0)}.to raise_error ArgumentError
    end

    it 'blocking pop' do
      q = LightIO::SizedQueue.new(1)
      b = LightIO::Beam.new {q.pop}
      b.join(0.01)
      expect(q.num_waiting).to be == 1
      q << "yes"
      expect(b.value).to be == "yes"
    end

    it 'blocking enqueue' do
      q = LightIO::SizedQueue.new(1)
      b = LightIO::Beam.new {q << 1; q << 1}
      b.join(0.01)
      expect(q.num_waiting).to be == 1
      expect(q.size).to be == 1
      q.pop
      expect(b.value).to be == q
    end

    it "#clear" do
      q = LightIO::SizedQueue.new(1)
      b = LightIO::Beam.new {q << 1; q << 1}
      b.join(0.01)
      expect(q.num_waiting).to be == 1
      expect(q.size).to be == 1
      q.clear # release the blocking
      expect(b.value).to be == q
      expect(q.empty?).to be_falsey
      expect(q.num_waiting).to be == 0
      q.clear
      expect(q.empty?).to be_truthy
    end

    it '#max=' do
      q = LightIO::SizedQueue.new(2)
      b = LightIO::Beam.new {q << 1; q << 1; q << 1}
      b.join(0.01)
      expect(q.num_waiting).to be == 1
      expect(q.size).to be == 2
      q.max = 1 # still blocking
      expect(q.num_waiting).to be == 1
      expect(q.size).to be == 2
      expect(b.join(0.01)).to be_nil
      q.max = 3 # release
      expect(b.value).to be == q
      expect(q.size).to be == 3
      expect(q.num_waiting).to be == 0
    end
  end
end