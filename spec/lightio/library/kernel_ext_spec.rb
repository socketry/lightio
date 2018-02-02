require 'spec_helper'

RSpec.describe LightIO::Library::KernelExt do
  context '#spawn' do
    it 'spawn' do
      from = Time.now.to_i
      LightIO.spawn("sleep 10")
      expect(Time.now.to_i - from).to be < 1
    end

    it 'spawn with io' do
      r, w = LightIO::Library::IO.pipe
      LightIO.spawn("date", out: w)
      expect(r.gets.split(':').size).to eq 3
      r.close; w.close
    end
  end
end