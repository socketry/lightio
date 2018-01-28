require 'spec_helper'

RSpec.describe LightIO::Library::IO do
  describe "act as IO" do
    it "#is_a?" do
      io = LightIO::Library::IO.new(1)
      expect(io).to be_a(LightIO::Library::IO)
      expect(io).to be_a(IO)
      expect(io).to be_kind_of(LightIO::Library::IO)
      expect(io).to be_kind_of(IO)
      io.close
    end

    it "#instance_of?" do
      io = LightIO::Library::IO.new(1)
      expect(io).to be_an_instance_of(LightIO::Library::IO)
      expect(io).to be_an_instance_of(IO)
      io.close
    end
  end

  describe "#wait methods" do
    it "#wait_readable" do
      r1, w1 = LightIO::Library::IO.pipe
      r2, w2 = LightIO::Library::IO.pipe
      b1 = LightIO::Beam.new {r1.gets}
      b2 = LightIO::Beam.new {r2.gets}
      b1.join(0.01); b2.join(0.01)
      w1.puts "foo "
      w2.puts "bar"
      expect(b1.value + b2.value).to be == "foo \nbar\n"
      [r1, r2, w1, w2].each(&:close)
    end
  end


  describe "#write" do
    it "#wait works" do
      r, w = LightIO::Library::IO.pipe
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

    it 'immediately return readable fd' do
      r1, w1 = LightIO::Library::IO.pipe
      w1.close
      read_fds, write_fds = LightIO::Library::IO.select([r1], nil, nil, 0)
      expect(read_fds).to be == [r1]
      expect(write_fds).to be == []
      r1.close
    end

    context 'implicit conversion' do

      class A_TO_IO
        attr_reader :to_io

        def initialize(io)
          @to_io = io
        end
      end

      class B_TO_IO
        def to_io
          1
        end
      end

      it 'should convert implicitly' do
        r1, w1 = LightIO::Library::IO.pipe
        a_r1, a_w1 = A_TO_IO.new(r1), A_TO_IO.new(w1)
        r2, w2 = LightIO::Library::IO.pipe
        a_r2, a_w2 = A_TO_IO.new(r2), A_TO_IO.new(w2)
        LightIO.sleep 0.1
        read_fds, write_fds = LightIO::Library::IO.select([a_r1, a_r2], [a_w1, a_w2])
        expect(read_fds).to be == []
        expect(write_fds).to be == [a_w1, a_w2]
        w1.close
        LightIO.sleep 0.1
        read_fds, write_fds = LightIO::Library::IO.select([a_r1, a_r2], [a_w2])
        expect(read_fds).to be == [a_r1]
        expect(write_fds).to be == [a_w2]
        r1.close
        r2.close
        w2.close
      end

      it 'raise error if no #to_io method' do
        expect {
          LightIO::Library::IO.select([1], nil)
        }.to raise_error(TypeError, "no implicit conversion of #{1.class} into IO")
      end

      it 'raise error if #to_io return not IO' do
        expect {
          LightIO::Library::IO.select([B_TO_IO.new], nil)
        }.to raise_error(TypeError, "can't convert B_TO_IO to IO (B_TO_IO#to_io gives #{1.class})")
      end
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

      it 'read eof' do
        r, w = pipe
        t1 = LightIO::Beam.new {r.read}
        t2 = LightIO::Beam.new {w.close}
        t1.join; t2.join
        expect(t1.value).to be == ''
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

      it 'read eof' do
        r, w = pipe
        t1 = LightIO::Beam.new {r.read(1)}
        t2 = LightIO::Beam.new {w.close}
        t1.join; t2.join
        expect(t1.value).to be_nil
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

  describe "#getbyte" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'read byte' do
      r, w = pipe
      t1 = LightIO::Beam.new {r.getbyte}
      t2 = LightIO::Beam.new {w.putc('n')}
      t1.join; t2.join
      expect(t1.value).to be == 'n'
    end

    it 'read eof' do
      r, w = pipe
      t1 = LightIO::Beam.new {r.getbyte}
      t2 = LightIO::Beam.new {w.close}
      t1.join; t2.join
      expect(t1.value).to be_nil
    end
  end

  describe "#getchar" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'read char' do
      r, w = pipe
      t1 = LightIO::Beam.new {r.getc}
      t2 = LightIO::Beam.new {w.putc('光')}
      t1.join; t2.join
      expect(t1.value).to be == '光'
    end

    it 'read eof' do
      r, w = pipe
      t1 = LightIO::Beam.new {r.getbyte}
      t2 = LightIO::Beam.new {w.close}
      t1.join; t2.join
      expect(t1.value).to be_nil
    end
  end

  describe "#eof?" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'block until eof' do
      r, w = pipe
      t1 = LightIO::Beam.new {r.eof?}
      expect(t1.join(0.001)).to be_nil
      w.close
      expect(t1.value).to be_truthy
    end

    it 'block until readable' do
      r, w = pipe
      t1 = LightIO::Beam.new {r.eof?}
      expect(t1.join(0.001)).to be_nil
      w << 'ok'
      expect(t1.value).to be_falsey
    end

    it 'read eof' do
      r, w = pipe
      w.close
      expect(r.eof?).to be_truthy
    end
  end

  describe "#gets" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    context 'gets' do
      it 'gets' do
        r, w = pipe
        w << "hello"
        t1 = LightIO::Beam.new {r.gets}
        expect(t1.join(0.001)).to be_nil
        w.write($/)
        expect(t1.value).to be == "hello\n"
      end

      it 'get all' do
        r, w = pipe
        w << "hello"
        t1 = LightIO::Beam.new {r.gets(nil)}
        expect(t1.join(0.001)).to be_nil
        w.write($/)
        expect(t1.join(0.001)).to be_nil
        w.close
        expect(t1.value).to be == "hello\n"
      end

      it 'read eof end' do
        r, w = pipe
        w << "hello"
        t1 = LightIO::Beam.new {r.gets}
        expect(t1.join(0.001)).to be_nil
        w.close
        expect(t1.value).to be == "hello"
      end

      it 'read eof' do
        r, w = pipe
        w.close
        t1 = LightIO::Beam.new {r.gets}
        expect(t1.value).to be_nil
      end

      it 'end with another char' do
        r, w = pipe
        w << 'hello'
        t1 = LightIO::Beam.new {r.gets('o')}
        expect(t1.value).to be == 'hello'
      end
    end

    context 'gets limit' do
      it 'non block' do
        r, w = pipe
        w << 'hello'
        expect(r.gets(3)).to be == 'hel'
      end

      it 'block' do
        r, w = pipe
        w << 'he'
        t1 = LightIO::Beam.new {r.gets(3)}
        expect(t1.join(0.001)).to be_nil
        w << 'l'
        expect(t1.value).to be == 'hel'
      end

      it 'sep' do
        r, w = pipe
        w.puts "he"
        t1 = LightIO::Beam.new {r.gets(5)}
        expect(t1.value).to be == "he\n"
      end
    end
  end

  describe "#readline" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'EOFError' do
      r, w = pipe
      w.close
      t1 = LightIO::Beam.new {r.readline}
      expect {t1.value}.to raise_error EOFError
    end
  end

  describe "#readchar" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'EOFError' do
      r, w = pipe
      w.close
      t1 = LightIO::Beam.new {r.readchar}
      expect {t1.value}.to raise_error EOFError
    end
  end

  describe "#readlines" do
    let(:pipe) {LightIO::Library::IO.pipe}
    after {pipe.each(&:close) rescue nil}

    it 'readlines' do
      r, w = pipe
      w.puts "hello"
      w.puts "world"
      w.close
      t1 = LightIO::Beam.new {r.readlines}
      expect(t1.value).to be == ["hello\n", "world\n"]
    end

    it 'block' do
      r, w = pipe
      w.puts "hello"
      w.puts "world"
      t1 = LightIO::Beam.new {r.readlines}
      expect(t1.join(0.001)).to be_nil
      w.close
    end

    it 'eof' do
      r, w = pipe
      w.close
      t1 = LightIO::Beam.new {r.readlines}
      expect(t1.value).to be == []
    end

    it 'read all' do
      r, w = pipe
      w.puts "hello"
      w.puts "world"
      w.close
      t1 = LightIO::Beam.new {r.readlines(nil)}
      expect(t1.value).to be == ["hello\nworld\n"]
    end

    it 'limit' do
      r, w = pipe
      w.puts "hello"
      w.puts "world"
      w.close
      t1 = LightIO::Beam.new {r.readlines(3)}
      expect(t1.value).to be == ["hel", "lo\n", "wor", "ld\n"]
    end
  end

  describe '#open' do
    it 'with block' do
      stdout = nil
      IO.open(1) do |io|
        stdout = io
        expect(io.to_i).to be == STDOUT.to_i
      end
      expect(stdout.closed?).to be_truthy
    end

    it 'without block' do
      io = IO.open(1)
      expect(io.to_i).to be == STDOUT.to_i
      expect(io.closed?).to be_falsey
      io.close
    end
  end
end