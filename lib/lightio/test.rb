require 'eventmachine'
require './patch'

LIO::Patch.patch

EventMachine.run do
  puts "hello"
  puts "hello"
  Fiber.new {sleep 5}.resume
  puts "hello"
end



