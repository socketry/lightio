require 'spec_helper'

RSpec.describe LightIO::Watchers::Timer do
  describe "register timer " do
    it "wait for interval seconds" do
      t1 = Time.now
      interval = 0.1
      timer = LightIO::Watchers::Timer.new interval
      LightIO::IOloop.current.wait(timer)
      expect(Time.now - t1).to be > interval
    end
  end
end