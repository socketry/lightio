require 'spec_helper'

RSpec.describe LightIO::ThreadsWait do
  describe "act as ThreadsWait" do
    it "#is_a?" do
      obj = LightIO::Library::ThreadsWait.new
      expect(obj).to be_a(LightIO::Library::ThreadsWait)
      expect(obj).to be_a(ThreadsWait)
      expect(obj).to be_kind_of(LightIO::Library::ThreadsWait)
      expect(obj).to be_kind_of(ThreadsWait)
    end

    it "#instance_of?" do
      obj = LightIO::Library::ThreadsWait.new {}
      expect(obj).to be_an_instance_of(LightIO::Library::ThreadsWait)
      expect(obj).to be_an_instance_of(ThreadsWait)
    end
  end

  describe "#all_waits" do
    it "wait all terminated" do
      threads = 5.times.map {LightIO::Thread.new {}}
      result = []
      LightIO::ThreadsWait.all_waits(*threads) do |t|
        result << t
      end
      expect(result) == threads
      expect(threads.any?(&:alive?)).to be_falsey
    end
  end

  describe "#next_wait" do
    it "non threads for waiting" do
      tw = LightIO::ThreadsWait.new
      expect(tw.empty?).to be_truthy
      expect {tw.next_wait}.to raise_error ThreadsWait::ErrNoWaitingThread
    end

    it "nonblock" do
      threads = 2.times.map {LightIO::Thread.new {LightIO.sleep(10)}}
      thr = LightIO::Thread.new {}
      thr.kill
      threads << thr
      tw = LightIO::ThreadsWait.new(*threads)
      expect(tw.finished?).to be_truthy
      expect(tw.next_wait(true)).to be == thr
      expect(tw.finished?).to be_falsey
    end

    it "nonblock but nofinished thread" do
      threads = 1.times.map {LightIO::Thread.new {LightIO.sleep(10)}}
      tw = LightIO::ThreadsWait.new(*threads)
      expect {tw.next_wait(true)}.to raise_error ThreadsWait::ErrNoFinishedThread
    end
  end
end