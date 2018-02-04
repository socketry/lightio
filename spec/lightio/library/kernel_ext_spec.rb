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

  context '#`' do
    it '`' do
      expect(LightIO.`("echo hello world")).to eq "hello world\n"
      expect($?.exitstatus).to eq 0
      LightIO.`("exit 128")
      expect($?.exitstatus).to eq 128
    end

    it 'error' do
      expect {LightIO.`("echeoooooo")}.to raise_error(Errno::ENOENT, 'No such file or directory - echeoooooo')
      expect($?.exitstatus).to eq 127
    end

    it 'concurrent' do
      start = Time.now
      10.times.map do
        LightIO::Beam.new {LightIO.`("sleep 0.2")}
      end.each(&:join)
      expect(Time.now - start).to be < 1
    end
  end

  context '#system' do
    it 'system' do
      expect(LightIO.system("echo hello world")).to be_truthy
      expect(LightIO.system("exit", "128")).to be_falsey
    end

    it 'error' do
      expect(LightIO.system("echeoooooo")).to be_nil
    end

    it 'concurrent' do
      start = Time.now
      10.times.map do
        LightIO::Beam.new {LightIO.system("sleep 0.2")}
      end.each(&:join)
      expect(Time.now - start).to be < 1
    end
  end
end