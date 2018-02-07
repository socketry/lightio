require 'net/http'
require 'webrick'

RSpec.describe Net::HTTP, skip_library: true do
  let(:port) {6666}
  let(:server) {
    WEBrick::HTTPServer.new(BindAddress: 'localhost', Port: port).tap do |server|
      server.mount_proc '/' do |req, res|
        res.body = 'Hello, world!'
      end

      server.mount_proc '/sleep' do |req, res|
        sleep 0.2
      end
    end
  }
  before(:each) {Thread.new {server.start}}
  after(:each) {server.shutdown}

  it 'should not block' do
    start = Time.now
    10.times.map do
      Thread.new do
        Net::HTTP.start('localhost', port) do |http|
          res = http.request_get('/sleep')
          expect(res.code).to eq "200"
        end
      end
    end.each(&:join)
    expect(Time.now - start).to be < 1
  end
end
