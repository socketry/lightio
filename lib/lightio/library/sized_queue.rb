require_relative 'queue'

module LightIO::Library
  class SizedQueue < LightIO::Library::Queue
    prepend LightIO::Module::SizedQueue
  end
end