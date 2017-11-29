require 'spec_helper'

RSpec.describe LightIO::Timer do
  describe "register timer " do
    it "wait for interval seconds" do
      timer = LightIO::Timer.new 0.1
      LightIO::IOloop.current.wait(timer)
      # done
    end
  end
end