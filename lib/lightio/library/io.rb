require 'forwardable'
module LightIO::Library
  class IO
    include LightIO::Wrap::Wrapper
    wrap ::IO

    extend Forwardable
    def_delegators :@io_watcher, :wait, :wait_readable, :wait_writable

    wrap_blocking_methods :read, :write, exception_symbol: false

    class << self
      def open(*args)
        io = self.new(*args)
        yield io
      ensure
        io.close if io.respond_to? :close
      end

      def pipe(*args)
        r, w = raw_class.pipe
        [IO._wrap(r), IO._wrap(w)]
      end
    end
  end
end
