require 'spec_helper'

RSpec.describe LightIO::IOPrimitive do
  describe "IO Primitive with beam" do
    it "works" do
      r, w = IO.pipe
      b = LightIO::Beam.new {LightIO.wait_read(r); r.read}
      expect(b.join(0.01)).to be_nil
      w.write "Hello IO"
      w.close
      expect(b.value).to be == "Hello IO"
    end

    it "works between beams" do
      r, w = IO.pipe
      b = LightIO::Beam.new {LightIO.wait_read(r); r.read}
      b2 = LightIO::Beam.new {LightIO.wait_write(w); w << "Hello"; w.close}
      b.join; b2.join
      expect(b.value).to be == "Hello"
    end

    it "works on main fiber" do
      r, w = IO.pipe
      LightIO::Beam.new {w << "Hello from Beam"; w.close}
      LightIO.wait_read(r)
      expect(r.read).to be == "Hello from Beam"
    end
  end

  describe "wait timeout" do
    it "beam wait timeout" do
      r, _w = IO.pipe
      b = LightIO::Beam.new {LightIO.wait_read(r, 0.001)}
      expect(b.value).to be_nil
    end

    it "root wait timeout" do
      r, _w = IO.pipe
      expect(LightIO.wait_read(r, 0.001)).to be_nil
    end
  end
end
