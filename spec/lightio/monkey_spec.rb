require 'spec_helper'

RSpec.describe LightIO::Monkey, skip_library: true do
  describe '#patch_thread!' do
    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
      expect(LightIO::Monkey.patched?(Thread)).to be_truthy
      expect(LightIO::Monkey.patched?(ThreadGroup)).to be_truthy
      expect(LightIO::Monkey.patched?(Thread::Mutex)).to be_truthy
      expect(LightIO::Monkey.patched?(Thread::Queue)).to be_truthy
      expect(LightIO::Monkey.patched?(Thread::SizedQueue)).to be_truthy
      expect(LightIO::Monkey.patched?(Thread::ConditionVariable)).to be_truthy
      expect(LightIO::Monkey.patched?(Mutex)).to be_truthy
      expect(LightIO::Monkey.patched?(Queue)).to be_truthy
      expect(LightIO::Monkey.patched?(SizedQueue)).to be_truthy
      expect(LightIO::Monkey.patched?(ConditionVariable)).to be_truthy
      expect(LightIO::Monkey.patched?(Timeout)).to be_truthy
      expect(LightIO::Monkey.patched?(ThreadsWait)).to be_truthy
      expect(LightIO::Monkey.patched?(Thread::ThreadsWait)).to be_truthy
    end

    it 'class methods is patched' do
      expect(Thread.new {}).to be_a(LightIO::Library::Thread)
      expect(Thread.new {Thread.current}.value).to be_a(LightIO::Library::Thread)
    end
  end

  describe '#patch_io!' do
    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
      expect(LightIO::Monkey.patched?(IO)).to be_truthy
      expect(LightIO::Monkey.patched?(File)).to be_truthy
      expect(LightIO::Monkey.patched?(Socket)).to be_truthy
      expect(LightIO::Monkey.patched?(TCPSocket)).to be_truthy
      expect(LightIO::Monkey.patched?(TCPServer)).to be_truthy
      expect(LightIO::Monkey.patched?(BasicSocket)).to be_truthy
      expect(LightIO::Monkey.patched?(Addrinfo)).to be_truthy
      expect(LightIO::Monkey.patched?(IPSocket)).to be_truthy
      expect(LightIO::Monkey.patched?(UDPSocket)).to be_truthy
      expect(LightIO::Monkey.patched?(UNIXSocket)).to be_truthy
      expect(LightIO::Monkey.patched?(UNIXServer)).to be_truthy
      expect(LightIO::Monkey.patched?(Process)).to be_truthy
      expect(LightIO::Monkey.patched?(OpenSSL::SSL::SSLSocket)).to be_truthy
    end

    it '#new' do
      io = IO.new(1)
      expect(io).to be_a(LightIO::Library::IO)
      io.close
    end

    it 'class methods is patched' do
      r, w = IO.pipe
      expect(r).to be_a(LightIO::Library::IO)
      expect(w).to be_a(LightIO::Library::IO)
      r.close; w.close
    end

    describe File do
      it '#new' do
        f = File.new("README.md", "r")
        expect(f).to be_a(File)
        f.close
      end

      it "#open" do
        f = File.new("README.md", "r")
        expect(f).to be_a(File)
        f.close
      end
    end

    describe "#accept_nonblock" do
      let(:port) {pick_random_port}
      let(:beam) {LightIO::Beam.new do
        TCPServer.open(port) {|serv|
          expect(serv).to be_a LightIO::Library::TCPServer
          IO.select([serv])
          s = serv.accept_nonblock
          expect(s).to be_a LightIO::Library::TCPSocket
          s.puts Process.pid.to_s
          s.close
        }
      end}

      it "work with raw socket client" do
        begin
          client = TCPSocket.new 'localhost', port
        rescue Errno::ECONNREFUSED
          beam.join(0.0001)
          retry
        end
        beam.join(0.0001)
        expect(client.gets).to be == "#{Process.pid.to_s}\n"
        client.close
      end
    end

    describe Process do
      context '#spawn' do
        it 'spawn' do
          from = Time.now.to_i
          Process.spawn("sleep 10")
          expect(Time.now.to_i - from).to be < 1
        end

        it 'spawn with io' do
          r, w = LightIO::Library::IO.pipe
          Process.spawn("date", out: w)
          expect(r.gets.split(':').size).to eq 3
          r.close; w.close
        end
      end
    end
  end

  describe '#patch_kernel!' do
    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
    end

    context 'kernel' do
      it '#select patched' do
        r, w = IO.pipe
        w.close
        expect {
          read_fds, write_fds = Kernel.select([r], nil, nil, 0)
        }.to_not raise_error
      end

      it '#sleep patched' do
        start = Time.now
        100.times.map {LightIO::Beam.new {Kernel.sleep 0.1}}.each(&:join)
        expect(Time.now - start).to be < 1
      end

      it '#open patched' do
        f = Kernel.open('/dev/stdin', 'r')
        expect(f).to be_a(LightIO::Library::File)
        f.close
      end
    end

    context 'main' do
      it '#select patched' do
        r, w = IO.pipe
        w.close
        expect {
          read_fds, write_fds = select([r], nil, nil, 0)
        }.to_not raise_error
      end

      it '#sleep patched' do
        start = Time.now
        100.times.map {LightIO::Beam.new {sleep 0.1}}.each(&:join)
        expect(Time.now - start).to be < 1
      end

      it '#open patched' do
        f = open('/dev/stdin', 'r')
        expect(f).to be_a(LightIO::Library::File)
        f.close
      end
    end

    context '#spawn' do
      it 'spawn' do
        from = Time.now.to_i
        spawn("sleep 10")
        expect(Time.now.to_i - from).to be < 1
      end

      it 'spawn with io' do
        r, w = IO.pipe
        spawn("date", out: w)
        expect(r.gets.split(':').size).to eq 3
        r.close; w.close
      end
    end

    context 'test open3' do
      require 'open3'
      it '#select patched' do
        from = Time.now.to_i
        Open3.popen3("sleep 10")
        expect(Time.now.to_i - from).to be < 1
      end
    end

    context '`' do
      it 'concurrent' do
        start = Time.now
        10.times.map do
          LightIO::Beam.new {`sleep 0.2`}
        end.each(&:join)
        expect(Time.now - start).to be < 1
      end
    end

    context 'system' do
      it 'concurrent' do
        start = Time.now
        10.times.map do
          LightIO::Beam.new {system("sleep 0.2")}
        end.each(&:join)
        expect(Time.now - start).to be < 1
      end
    end

    context 'io methods' do
      it 'should yield' do
        result = []
        Thread.new {result << 1}
        expect(result).to eq []
        expect {
          Timeout.timeout(0.1) {gets}
        }.to raise_error(Timeout::Error)
        expect(result).to eq [1]
      end
    end
  end
end