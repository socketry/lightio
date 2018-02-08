RSpec.describe IO do
  describe 'inherited from IO with nameless class' do
    it "#is_a? & #instance_of?" do
      klass = Class.new(IO)
      io = klass.new(1)
      expect(io).to be_a(LightIO::Library::IO)
      expect(io).to be_a(IO)
      expect(io).to_not be_an_instance_of(LightIO::Library::IO)
      expect(io).to_not be_an_instance_of(IO)
      io.close
    end

    it ".pipe" do
      klass = Class.new(IO)
      r, w = klass.pipe
      expect(r).to be_an_instance_of(klass)
      expect(w).to be_an_instance_of(klass)
      w << "hello"
      w.close
      expect(r.read).to eq "hello"
      r.close; w.close
    end
  end

  class IOFake < ::IO
  end

  describe 'inherited from IO' do
    it "#is_a? & #instance_of?" do
      io = IOFake.new(1)
      expect(io).to be_a(LightIO::Library::IO)
      expect(io).to be_a(IO)
      expect(io).to_not be_an_instance_of(LightIO::Library::IO)
      expect(io).to_not be_an_instance_of(IO)
      io.close
    end

    it ".pipe" do
      r, w = IOFake.pipe
      expect(r).to be_an_instance_of(IOFake)
      expect(w).to be_an_instance_of(IOFake)
      w << "hello"
      w.close
      expect(r.read).to eq "hello"
      r.close; w.close
    end
  end
end
