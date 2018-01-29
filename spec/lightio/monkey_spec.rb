require 'spec_helper'

RSpec.describe LightIO::Monkey do
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

  describe '#patch_socket!' do
    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
      expect(LightIO::Monkey.patched?(IO)).to be_truthy
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

    it 'class methods is patched' do
      r, w = IO.pipe
      expect(r).to be_a(LightIO::Library::IO)
      expect(w).to be_a(LightIO::Library::IO)
      r.close; w.close
    end

    describe "#accept_nonblock" do
      let(:port) {pick_random_port}
      let(:beam) {LightIO::Beam.new do
        TCPServer.open(port) {|serv|
          expect(serv).to be_a LightIO::Library::TCPServer
          IO.select([serv])
          s = serv.accept_nonblock
          expect(s).to be_a LightIO::Library::TCPSocket
          s.puts Date.today
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
        expect(client.gets).to be == "#{Date.today.to_s}\n"
        client.close
      end
    end
  end

  describe '#patch_kernel!' do
    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
      expect(LightIO::Monkey.patched?(Thread)).to be_falsey
      expect(LightIO::Monkey.patched?(IO)).to be_falsey
    end

    it '#get_origin' do
      expect(LightIO::Monkey.get_origin(IO)).to be_nil
      expect(LightIO::Monkey.get_origin(Thread)).to be_nil
    end

    it '#select patched' do
      r, w = IO.pipe
      w.close
      expect {
        read_fds, write_fds = select([r], nil, nil, 0)
      }.to raise_error(TypeError, "can't process raw IO, use LightIO::IO._wrap(obj) to wrap it")
    end

    it '#sleep patched' do
      start = Time.now
      100.times.map {LightIO::Beam.new {sleep 0.1}}.each(&:join)
      expect(Time.now - start).to be < 1
    end
  end
end