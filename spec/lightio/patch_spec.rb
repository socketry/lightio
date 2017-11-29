require 'eventmachine'
require 'spec_helper'


RSpec.describe LightIO do
# LIO::Patch.patch

  EventMachine.run do
    puts "hello"
    puts "hello"
    Fiber.new {sleep 5}.resume
    puts "hello"
    EventMachine.stop
  end
end


