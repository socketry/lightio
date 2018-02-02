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
end
