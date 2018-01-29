module LightIO::Library
  class IO
    include Base
    include LightIO::Wrap::IOWrapper

    mock ::IO
    extend LightIO::Module::IO::ClassMethods

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
          return length.nil? ? outbuf : nil
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
      @obj.getc
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
      @obj.eof
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

    def to_io
      self
    end

    def close(*args)
      # close watcher before io closed
      io_watcher.close
      @obj.close
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
      io_watcher.wait_readable
    end
  end
end
