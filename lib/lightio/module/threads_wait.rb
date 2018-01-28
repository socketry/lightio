require 'thwait'

module LightIO::Module
  module ThreadsWait
    include LightIO::Module::Base

    module ClassMethods
      def all_waits(*threads, &blk)
        LightIO::Library::ThreadsWait.new(*threads).all_waits(&blk)
      end
    end
  end
end
