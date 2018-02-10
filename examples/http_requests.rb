require 'lightio'
# apply monkey patch at beginning
LightIO::Monkey.patch_all!

require 'net/http'

host = 'github.com'
port = 80

start = Time.now

10.times.map do
  Thread.new do
    Net::HTTP.start(host, port, use_ssl: false) do |http|
      res = http.request_get('/ping')
      p res.code
    end
  end
end.each(&:join)

p Time.now - start