require 'spec_helper'

RSpec.describe LightIO::Library::IO do
  describe "#open" do
    it "return file" do
      f = LightIO::Library::File.open('/dev/stdin', 'r')
      expect(f).to be_a(LightIO::Library::File)
      expect(f).to be_a(File)
      expect(f).to be_kind_of(LightIO::Library::File)
      expect(f).to be_kind_of(File)
      f.close
    end
  end

  describe "#pipe" do
    it "works with beam" do
      r1, w1 = LightIO::Library::File.pipe
      r2, w2 = LightIO::Library::File.pipe
      b1 = LightIO::Beam.new {r1.gets}
      b2 = LightIO::Beam.new {r2.gets}
      b1.join(0.01); b2.join(0.01)
      w1.puts "foo "
      w2.puts "bar"
      expect(b1.value + b2.value).to be == "foo \nbar\n"
      [r1, r2, w1, w2].each(&:close)
    end
  end
end
