require 'spec_helper'

RSpec.describe LightIO::Monkey do
  describe '#patch_thread!' do
    before(:all) {LightIO::Monkey.patch_thread!}
    after(:all) {LightIO::Monkey.unpatch_thread!}

    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
      expect(LightIO::Monkey.patched?(IO)).to be_falsey
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

    it '#get_origin' do
      thread_class = LightIO::Monkey.get_origin(Thread)
      expect(thread_class).to be == Thread::RAW_THREAD
    end
  end

  describe '#patch_socket!' do
    before(:all) {LightIO::Monkey.patch_socket!}
    after(:all) {LightIO::Monkey.unpatch_socket!}

    it '#patched?' do
      expect(LightIO::Monkey.patched?(LightIO)).to be_falsey
      expect(LightIO::Monkey.patched?(Thread)).to be_falsey
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

    it '#get_origin' do
      io_class = LightIO::Monkey.get_origin(IO)
      expect(io_class).to be == STDOUT.class
    end
  end

  describe '#patch_kernel!' do
    before(:all) {LightIO::Monkey.patch_kernel!}
    after(:all) {LightIO::Monkey.unpatch_kernel!}

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