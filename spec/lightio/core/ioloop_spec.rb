require 'spec_helper'

RSpec.describe LightIO::IOloop do
  it "auto started" do
    t = Thread.new {LightIO::IOloop.current.closed?}
    expect(t.value).to be_falsey
  end

  it "per threaded" do
    t = Thread.new {LightIO::IOloop.current}
    expect(t.value).to_not be == LightIO::IOloop.current
  end

  describe "#close" do
    it "#closed?" do
      result = []
      t = Thread.new {
        result << LightIO::IOloop.current.closed?
        LightIO::IOloop.current.close
        result << LightIO::IOloop.current.closed?
      }
      expect(result).to eql [false, true]
    end

    it "raise error" do
      t = Thread.new {
        LightIO::IOloop.current.stop
        r, w = LightIO::IO.pipe
        w.puts "hello"
        w.close
        r.read
      }
      expect {t.value}.to raise_error(IOError, 'selector is closed')
    end
  end
end