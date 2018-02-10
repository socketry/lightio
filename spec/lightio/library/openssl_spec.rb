RSpec.describe OpenSSL::SSL::SSLSocket do
  describe "#to_io" do
    it 'to_io return socket' do
      r, w = LightIO::Library::IO.pipe
      s = LightIO::Library::OpenSSL::SSL::SSLSocket.new(w)
      expect(s.to_io).to be_instance_of(LightIO::Library::IO)
      expect(s.to_io).to eq s.io
      s.close
      r.close; w.close
    end

    it 'to_io return raw socket', skip_monkey_patch: true do
      r, w = IO.pipe
      s = LightIO::Library::OpenSSL::SSL::SSLSocket.new(w)
      expect(s.to_io).to be_instance_of(IO)
      expect(s.to_io).to_not be_instance_of(LightIO::Library::IO)
      s.close
      r.close; w.close
    end
  end
end
