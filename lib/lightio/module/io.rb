module LightIO::Module
  extend Base::NewHelper

  define_new_for_module "IO"

  module IO
    include LightIO::Module::Base

    class << self
      # helper methods
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
        io.__send__(:io_watcher)
      end
    end

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
        r, w = origin_pipe(*args)
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

      def copy_stream(*args)
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 2..4)" unless (2..4).include?(args.size)
        src, dst, copy_length, src_offset = args
        src = src.respond_to?(:to_io) ? src.to_io : LightIO::Library::File.open(src, 'r') unless src.is_a?(IO)
        dst = dst.respond_to?(:to_io) ? dst.to_io : LightIO::Library::File.open(dst, 'w') unless dst.is_a?(IO)
        buf_size = 4096
        copy_chars = 0
        buf_size = [buf_size, copy_length].min if copy_length
        src.seek(src_offset) if src_offset
        while (buf = src.read(buf_size))
          size = dst.write(buf)
          copy_chars += size
          if copy_length
            copy_length -= size
            break if copy_length.zero?
            buf_size = [buf_size, copy_length].min
          end
        end
        copy_chars
      end

      def select(read_fds, write_fds=nil, _except_fds=nil, timeout=nil)
        timer = timeout && Time.now
        read_fds ||= []
        write_fds ||= []
        loop do
          # make sure io registered, then clear io watcher status
          read_fds.each {|fd| LightIO::Module::IO.get_io_watcher(fd).tap {|io| io.readable?; io.clear_status}}
          write_fds.each {|fd| LightIO::Module::IO.get_io_watcher(fd).tap {|io| io.writable?; io.clear_status}}
          # run ioloop once
          LightIO.sleep 0
          r_fds = read_fds.select {|fd|
            io = LightIO::Module::IO.convert_to_io(fd)
            io.closed? ? raise(IOError, 'closed stream') : LightIO::Module::IO.get_io_watcher(io).readable?
          }
          w_fds = write_fds.select {|fd|
            io = LightIO::Module::IO.convert_to_io(fd)
            io.closed? ? raise(IOError, 'closed stream') : LightIO::Module::IO.get_io_watcher(io).writable?
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
    end
  end
end
