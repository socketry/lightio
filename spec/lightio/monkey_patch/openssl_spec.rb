RSpec.describe OpenSSL::SSL::SSLSocket, skip_library: true do
  describe 'new' do
    it "#is_a? & #instance_of?" do
      r, w = IO.pipe
      s = OpenSSL::SSL::SSLSocket.new(w)
      expect(s).to be_a(LightIO::Library::OpenSSL::SSL::SSLSocket)
      expect(s).to be_a(OpenSSL::SSL::SSLSocket)
      expect(s).to be_an_instance_of(LightIO::Library::OpenSSL::SSL::SSLSocket)
      expect(s).to be_an_instance_of(OpenSSL::SSL::SSLSocket)
      s.close
      r.close; w.close
    end

    it "select" do
      r, w = IO.pipe
      s = OpenSSL::SSL::SSLSocket.new(w)
      reads, writes, _ = IO.select([], [w])
      expect(writes) == [w]
      s.close
      r.close; w.close
    end
  end

  describe 'inherited' do
    it 'success' do
      MySSLSocket = Class.new(::OpenSSL::SSL::SSLSocket)
      expect(MySSLSocket < OpenSSL::SSL::SSLSocket)
    end
  end
end
