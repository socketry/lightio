require 'spec_helper'

RSpec.describe LightIO::IOPrimitive do
  describe "IO Primitive with beam" do
    it "#wait_read works" do
      r, w = IO.pipe
      b = LightIO::Beam.new {LightIO.wait_read(r); r.read}
      expect(b.join(0.001)).to be_nil
      w.write "Hello IO"
      w.close
      expect(b.value).to be == "Hello IO"
    end

    it "#wait_read and #wait_write between beams" do
      r, w = IO.pipe
      b = LightIO::Beam.new {LightIO.wait_read(r); r.read}
      b2 = LightIO::Beam.new {LightIO.wait_write(w); w << "Hello"; w.close}
      b.join; b2.join
      expect(b.value).to be == "Hello"
    end

    it "#wait_read on main fiber" do
      r, w = IO.pipe
      LightIO::Beam.new {w << "Hello from Beam"; w.close}
      LightIO.wait_read(r)
      expect(r.read).to be == "Hello from Beam"
    end
  end

  describe "#wait_read with timeout" do
    it "beam wait until timeout" do
      r, _w = IO.pipe
      b = LightIO::Beam.new {LightIO.wait_read(r, 0.001)}
      expect(b.value).to be_nil
    end

    it "root wait until timeout" do
      r, _w = IO.pipe
      expect(LightIO.wait_read(r, 0.001)).to be_nil
    end
  end

  describe "#wait_read multiple io at same time" do
    it "two beams wait two pipe" do
      results = 2.times.map do
        r, w = IO.pipe
        cr, cw = IO.pipe
        b = LightIO::Beam.new {
          while LightIO.wait_read(cr)
            data = cr.readline
            w.puts(data)
          end
        }
        [b, r, cw]
      end
      b1, r1, w1 = results[0]
      b2, r2, w2 = results[1]
      b1.join(0.001); b2.join(0.001)
      w1.puts("hello")
      LightIO.wait_read(r1)
      expect(r1.readline).to be == "hello\n"
      w2.puts("world")
      LightIO.wait_read(r2)
      expect(r2.readline).to be == "world\n"
      w1.puts("b1 still works")
      LightIO.wait_read(r1)
      expect(r1.readline).to be == "b1 still works\n"
      w2.puts("b2 is also cool")
      LightIO.wait_read(r2)
      expect(r2.readline).to be == "b2 is also cool\n"
    end
  end
end
