module LightIO::Module
  module IO
    module ClassMethods
      include LightIO::Module::Base::Helper

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
        [wrap_to_library(r), wrap_to_library(w)]
      end

      def select(read_fds, write_fds=nil, _except_fds=nil, timeout=nil)
        timer = timeout && Time.now
        read_fds ||= []
        write_fds ||= []
        loop do
          # make sure io registered, then clear io watcher status
          read_fds.each {|fd| get_io_watcher(fd).tap {|io| io.readable?; io.clear_status}}
          write_fds.each {|fd| get_io_watcher(fd).tap {|io| io.writable?; io.clear_status}}
          # run ioloop once
          LightIO.sleep 0
          r_fds = read_fds.select {|fd|
            io = convert_to_io(fd)
            io.closed? ? raise(IOError, 'closed stream') : get_io_watcher(io).readable?
          }
          w_fds = write_fds.select {|fd|
            io = convert_to_io(fd)
            io.closed? ? raise(IOError, 'closed stream') : get_io_watcher(io).writable?
          }
          e_fds = []
          if r_fds.empty? && w_fds.empty?
            if timeout && Time.now - timer > timeout
              return nil
            end
          else
            return [r_fds, w_fds, e_fds]
          end
        end
      end

      private
      def convert_to_io(io)
        unless io.respond_to?(:to_io)
          raise TypeError, "no implicit conversion of #{io.class} into IO"
        end
        to_io = io.to_io
        unless to_io.is_a?(LightIO::Library::IO)
          raise TypeError, "can't process raw IO, use LightIO::IO._wrap(obj) to wrap it" if to_io.is_a?(::IO)
          raise TypeError, "can't convert #{io.class} to IO (#{io.class}#to_io gives #{to_io.class})"
        end
        to_io
      end

      def get_io_watcher(io)
        unless io.is_a?(LightIO::Library::IO)
          io = convert_to_io(io)
        end
        io.instance_variable_get(:@io_watcher)
      end
    end
  end
end
