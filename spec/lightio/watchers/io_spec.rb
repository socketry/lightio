require 'spec_helper'

RSpec.describe LightIO::Watchers::IO do
  describe "Watchers::IO" do
    it 'can not call wait on closed io watcher' do
      r, w = IO.pipe
      io_watcher = LightIO::Watchers::IO.new(r, :r)
      io_watcher.close
      expect {io_watcher.wait_readable}.to raise_error(EOFError)
    end

    it 'can not cross threads' do
      r, w = IO.pipe
      io_watcher = LightIO::Watchers::IO.new(r, :r)
      expect {Thread.start {io_watcher.wait_readable}.value}.to raise_error(LightIO::Error)
      io_watcher.close
      r.close; w.close
    end
  end

  describe "Watchers::IO with beam" do
    it "#wait_read works" do
      r, w = IO.pipe
      b = LightIO::Beam.new {
        io_watcher = LightIO::Watchers::IO.new(r, :r)
        io_watcher.wait_readable
        data = r.read
        io_watcher.close
        data
      }
      expect(b.join(0.001)).to be_nil
      w.write "Hello IO"
      w.close
      expect(b.value).to be == "Hello IO"
    end

    it "#wait_read and #wait_write between beams" do
      r, w = IO.pipe
      b = LightIO::Beam.new {
        io_watcher = LightIO::Watchers::IO.new(r, :r)
        io_watcher.wait_readable
        data = r.read
        io_watcher.close
        data
      }
      b2 = LightIO::Beam.new {
        io_watcher = LightIO::Watchers::IO.new(w, :w)
        io_watcher.wait_writable
        w << "Hello"
        io_watcher.close
        w.close
      }
      b.join; b2.join
      expect(b.value).to be == "Hello"
    end

    it "#wait_read on main fiber" do
      r, w = IO.pipe
      LightIO::Beam.new {w << "Hello from Beam"; w.close}
      io_watcher = LightIO::Watchers::IO.new(r, :r)
      io_watcher.wait_readable
      expect(r.read).to be == "Hello from Beam"
      io_watcher.close
    end
  end

  describe "#wait_read with timeout" do
    it "beam wait until timeout" do
      r, _w = IO.pipe
      b = LightIO::Beam.new {
        io_watcher = LightIO::Watchers::IO.new(r, :r)
        data = if io_watcher.wait_readable(0.001)
                 r.read
               end
        io_watcher.close
        data
      }
      expect(b.value).to be_nil
    end

    it "root wait until timeout" do
      r, _w = IO.pipe
      io_watcher = LightIO::Watchers::IO.new(r, :r)
      data = if io_watcher.wait_readable(0.001)
               r.read
             end
      io_watcher.close
      data
      expect(data).to be_nil
    end
  end

  describe "#wait_read multiple io at same time" do
    it "two beams wait two pipe" do
      results = 2.times.map do
        r, w = IO.pipe
        cr, cw = IO.pipe
        b = LightIO::Beam.new(cr, w) {|r, w|
          io_watcher = LightIO::Watchers::IO.new(r, :r)
          loop do
            io_watcher.wait_readable
            data = r.readline
            w.puts(data)
          end
          io_watcher.close
        }
        [b, r, cw]
      end
      b1, r1, w1 = results[0]
      b2, r2, w2 = results[1]
      b1.join(0.001); b2.join(0.001)
      w1.puts("hello")
      r1_watcher = LightIO::Watchers::IO.new(r1, :r)
      r1_watcher.wait_readable
      expect(r1.readline).to be == "hello\n"
      w2.puts("world")
      r2_watcher = LightIO::Watchers::IO.new(r2, :r)
      r2_watcher.wait_readable
      expect(r2.readline).to be == "world\n"
      w1.puts("b1 still works")
      r1_watcher.wait_readable
      expect(r1.readline).to be == "b1 still works\n"
      w2.puts("b2 is also cool")
      r2_watcher.wait_readable
      expect(r2.readline).to be == "b2 is also cool\n"
      r1_watcher.close
      r2_watcher.close
    end
  end
end
