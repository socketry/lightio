require 'forwardable'
module LightIO::Library
  class IO
    include LightIO::Wrap::IOWrapper
    wrap ::IO

    wrap_blocking_methods :read, :write

    alias_method :<<, :write

    def read(length=nil, outbuf=nil)
      raise ArgumentError, "negative length #{length} given" if length && length < 0
      (outbuf ||= "").clear
      loop do
        readlen = length.nil? ? 4096 : length - outbuf.size
        if (data = wait_nonblock(:read_nonblock, readlen))
          outbuf << data
          if length == outbuf.size
            return outbuf
          end
        else
          return length.nil? ? '' : nil
        end
      end
    end

    def readpartial(maxlen, outbuf=nil)
      (outbuf ||= "").clear
      if (data = wait_nonblock(:read_nonblock, maxlen))
        outbuf << data
      else
        raise EOFError, 'end of file reached'
      end
      outbuf
    end

    def getbyte
      read(1)
    end

    def getc
      wait_readable
      @io.getc
    end

    def readline(*args)
      line = gets(*args)
      raise EOFError, 'end of file reached' if line.nil?
      line
    end

    def readlines(*args)
      result = []
      until eof?
        result << readline(*args)
      end
      result
    end

    def readchar
      c = getc
      raise EOFError, 'end of file reached' if c.nil?
      c
    end

    def readbyte
      b = getbyte
      raise EOFError, 'end of file reached' if b.nil?
      b
    end

    def eof
      wait_readable
      @io.eof?
    end

    alias eof? eof

    def gets(*args)
      raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..2)" if args.size > 2
      return nil if eof?
      sep = $/
      if args[0].is_a?(Numeric)
        limit = args.shift
      else
        sep = args.shift if args.size > 0
        limit = args.shift if args.first.is_a?(Numeric)
      end
      s = ''
      while (c = getc)
        s << c
        break if limit && s.size == limit
        break if c == sep
      end
      $_ = s
    end

    def close(*args)
      # close watcher before io closed
      @io_watcher.close
      @io.close(*args)
    end

    def to_io
      self
    end

    private
    def wait_readable
      # if IO is already readable, continue wait_readable may block it forever
      # so use getbyte detect this situation
      # Maybe move getc and gets to thread pool is a good idea
      b = getbyte
      if b
        ungetbyte(b)
        return
      end
      @io_watcher.wait_readable
    end

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
        r, w = raw_class.pipe
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

      def select(read_fds, write_fds=nil, _except_fds=nil, timeout=nil)
        timer = timeout && Time.now
        read_fds ||= []
        write_fds ||= []
        loop do
          # clear io watcher status
          read_fds.each {|fd| get_io_watcher(fd).clear_status}
          write_fds.each {|fd| get_io_watcher(fd).clear_status}
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
        unless to_io.is_a?(IO)
          raise TypeError, "can't convert #{io.class} to IO (#{io.class}#to_io gives #{to_io.class})"
        end
        to_io
      end

      def get_io_watcher(io)
        unless io.is_a?(IO)
          io = convert_to_io(io)
        end
        io.instance_variable_get(:@io_watcher)
      end
    end
  end
end
