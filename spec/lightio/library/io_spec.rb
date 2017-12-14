require 'spec_helper'

RSpec.describe LightIO::Library::IO do
  describe "#wait methods" do
    it "#wait_readable" do
      r1, w1 = LightIO::Library::IO.pipe
      r2, w2 = LightIO::Library::IO.pipe
      b1 = LightIO::Beam.new {r1.wait_readable; r1.gets}
      b2 = LightIO::Beam.new {r2.wait_readable; r2.gets}
      b1.join(0.0001); b2.join(0.0001)
      w1.puts "foo "
      w2.puts "bar"
      expect(b1.value + b2.value).to be == "foo \nbar\n"
    end
  end

  describe "#close" do
    it 'should close io watcher too' do
      r, w = LightIO::Library::IO.pipe
      r.close
      w.close
      expect(r.instance_variable_get(:@io_watcher).closed?).to be_truthy
      expect(w.instance_variable_get(:@io_watcher).closed?).to be_truthy
    end
  end
end