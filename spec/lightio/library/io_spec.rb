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
      [r1, r2, w1, w2].each(&:close)
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

    it 'call on closed io' do
      r, w = LightIO::Library::IO.pipe
      r.close
      w.close
      expect {r.read(1)}.to raise_error(IOError)
      expect {w.write("test")}.to raise_error(IOError)
    end
  end

  describe "#pipe" do
    it 'closed after block' do
      rd, wd = LightIO::Library::IO.pipe do |r, w|
        [r, w]
      end
      expect(rd.closed?).to be_truthy
      expect(wd.closed?).to be_truthy
    end
  end

  describe "#select" do
    it 'should return select fds' do
      r1, w1 = LightIO::Library::IO.pipe
      r2, w2 = LightIO::Library::IO.pipe
      LightIO.sleep 0.1
      read_fds, write_fds = LightIO::Library::IO.select([r1, r2], [w1, w2])
      expect(read_fds).to be == []
      expect(write_fds).to be == [w1, w2]
      w1.close
      LightIO.sleep 0.1
      read_fds, write_fds = LightIO::Library::IO.select([r1, r2], [w2])
      expect(read_fds).to be == [r1]
      expect(write_fds).to be == [w2]
      r1.close
      r2.close
      w2.close
    end

    it 'should raise io error if fd is closed' do
      r, w = LightIO::Library::IO.pipe
      w.close
      expect {LightIO::Library::IO.select([r], [w])}.to raise_error(IOError)
      r.close
    end

    it 'should blocking until timeout if no io readable' do
      r, w = LightIO::Library::IO.pipe
      expect(LightIO::Library::IO.select([r], [], [], 0.0001)).to be_nil
      r.close
      w.close
    end
  end
end