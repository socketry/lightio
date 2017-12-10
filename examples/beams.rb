require 'lightio'

start = Time.now

beams = 1000.times.map do
  # LightIO::Beam is a thread-like executor, use it instead Thread
  LightIO::Beam.new do
    # do some io operations in beam
    LightIO.sleep(1)
  end
end

beams.each(&:join)
seconds = Time.now - start
puts "1000 beams take #{seconds - 1} seconds to create"
