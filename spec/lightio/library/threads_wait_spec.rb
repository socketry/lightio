require 'spec_helper'

RSpec.describe LightIO::ThreadsWait do
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