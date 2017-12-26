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


  describe "#write" do
    it "#wait works" do
      r, w = IO.pipe
      if RUBY_VERSION > '2.5.0'
        w.write "Hello", "IO"
      else
        w.write "Hello IO"
      end
      w.close
      expect(r.read).to be == "Hello IO"
      r.close
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

  describe "#read" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'length is negative' do
      r, w = pipe
      expect {r.read(-1)}.to raise_error(ArgumentError)
    end

    context 'length is nil' do
      it "should read until EOF" do
        r, w = pipe
        w.puts "hello"
        w.puts "world"
        w.close
        expect(r.read) == "hello\nworld\n"
        expect(r.read) == ""
        expect(r.read(nil)) == ""
      end

      it "use outbuf" do
        r, w = pipe
        w.puts "hello"
        w.puts "world"
        w.close
        outbuf = "origin content should be remove"
        expect(r.read(nil, outbuf)) == "hello\nworld\n"
        expect(outbuf) == "hello\nworld\n"
      end

      it "blocking until read EOF" do
        r, w = pipe
        w.puts "hello"
        w.puts "world"
        expect do
          LightIO::Timeout.timeout(0.0001) do
            r.read
          end
        end.to raise_error(LightIO::Timeout::Error)
        w.close
        expect(r.read) == "hello\nworld\n"
      end
    end

    context 'length is positive' do
      it "should read length" do
        r, w = pipe
        w.puts "hello"
        w.puts "world"
        w.close
        expect(r.read(5)) == "hello"
        expect(r.read(1)) == "\n"
        expect(r.read) == "world\n"
      end

      it "use outbuf" do
        r, w = pipe
        w.puts "hello"
        w.puts "world"
        w.close
        outbuf = "origin content should be remove"
        expect(r.read(5, outbuf)) == "hello"
        expect(outbuf) == "hello"
      end

      it "blocking until read length" do
        r, w = pipe
        w.write "hello"
        expect do
          LightIO::Timeout.timeout(0.0001) do
            r.read(10)
          end
        end.to raise_error(LightIO::Timeout::Error)
        w.write "world"
        w.close
        expect(r.read(10)) == "helloworld"
      end
    end

    describe "#readpartial" do
      let(:pipe) {LightIO::Library::IO.pipe}
      after {pipe.each(&:close) rescue nil}

      it 'length is negative' do
        r, w = pipe
        expect {r.readpartial(-1)}.to raise_error(ArgumentError)
      end

      it "return immediately content" do
        r, w = pipe
        w << "hello"
        expect(r.readpartial(4096)) == "hello"
      end

      it "raise EOF" do
        r, w = pipe
        w << "hello"
        w.close
        expect(r.readpartial(4096)) == "hello"
        expect {r.readpartial(4096)}.to raise_error EOFError
      end

      it "with outbuf" do
        r, w = pipe
        w << "hello"
        outbuf = "origin content should be remove"
        expect(r.readpartial(4096, outbuf)) == "hello"
        expect(outbuf) == "hello"
      end

      it "blocking until readable" do
        r, w = pipe
        expect do
          LightIO::Timeout.timeout(0.0001) do
            r.readpartial(4096)
          end
        end.to raise_error(LightIO::Timeout::Error)
        w << "hello world"
        w.close
        expect(r.readpartial(4096)) == "hello world"
      end
    end
  end
end