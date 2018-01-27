module LightIO::Library
  class IO
    include Base
    mock ::IO
    prepend LightIO::Module::IO

    class << self
      def open(*args)
        io = self.new(*args)
        return io unless block_given?
        begin
          yield io
        ensure
          io.close if io.respond_to? :close
        end
      end

      def pipe(*args)
        r, w = mock_klass.pipe(*args)
        if block_given?
          begin
            return yield r, w
          ensure
            w.close
            r.close
          end
        end
        [IO._wrap(r), IO._wrap(w)]
      end
    end
  end
end
