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
  end

  describe '#patch_kernel!' do
    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
    end

    it '#select patched' do
      r, w = IO.pipe
      w.close
      expect {
        # rspec also provide a `select` dsl, it breaks lightio monkey patch, so here we use Kernel.select
        read_fds, write_fds = Kernel.select([r], nil, nil, 0)
      }.to_not raise_error
    end

    it '#sleep patched' do
      # rspec also provide a `sleep` dsl, it breaks lightio monkey patch, so here we use Kernel.sleep
      start = Time.now
      100.times.map {LightIO::Beam.new {Kernel.sleep 0.1}}.each(&:join)
      expect(Time.now - start).to be < 1
    end
  end
end