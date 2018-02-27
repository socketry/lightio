require 'io/wait'

module LightIO::Library
  class IO
    include Base
    include LightIO::Wrap::IOWrapper

    mock ::IO
    extend LightIO::Module::IO::ClassMethods

    def to_io
      self
    end

    # abstract for io-like operations
    module IOMethods
      class << self
        def included(base)
          base.send(:wrap_blocking_methods, :read, :write)
          base.send(:alias_method, :<<, :write)
        end
      end

      def lightio_initialize
        @readbuf = StringIO.new
        @readbuf.set_encoding(@obj.external_encoding) if @obj.respond_to?(:external_encoding)
        @eof = nil
        @seek = 0
      end

      def wait(timeout = nil, mode = :read)
        # avoid wait if can immediately return
        (super(0, mode) || io_watcher.wait(timeout, mode)) && self
      end

      def wait_readable(timeout = nil)
        wait(timeout, :read) && self
      end

      def wait_writable(timeout = nil)
        wait(timeout, :write) && self
      end

      def read(length = nil, outbuf = nil)
        while !fill_read_buf && (length.nil? || length > @readbuf.length - @readbuf.pos)
          wait_readable
        end
        @readbuf.read(length, outbuf)
      end

      def readpartial(maxlen, outbuf = nil)
        raise ArgumentError, "negative length #{maxlen} given" if maxlen < 0
        fill_read_buf
        while @readbuf.eof? && !io_eof?
          wait_readable
          fill_read_buf
        end
        @readbuf.readpartial(maxlen, outbuf)
      end

      def getbyte
        read(1)
      end

      def getc
        fill_read_buf
        until (c = @readbuf.getc)
          return nil if nonblock_eof?
          wait_readable
          fill_read_buf
        end
        c
      end

      def readline(*args)
        line = gets(*args)
        raise EOFError, 'end of file reached' if line.nil?
        line
      end

      def readlines(*args)
        until fill_read_buf
          wait_readable
        end
        @readbuf.readlines(*args)
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
        # until eof have a value
        fill_read_buf
        while @readbuf.eof? && @eof.nil?
          wait_readable
          fill_read_buf
        end
        nonblock_eof?
      end

      alias eof? eof

      def gets(*args)
        raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..2)" if args.size > 2
        sep = $/
        if args[0].is_a?(Numeric)
          limit = args[0]
        else
          sep = args[0] if args.size > 0
          limit = args[1] if args[1].is_a?(Numeric)
        end
        until fill_read_buf
          break if limit && limit <= @readbuf.length
          break if sep && @readbuf.string.index(sep)
          wait_readable
        end
        @readbuf.gets(*args)
      end

      def print(*obj)
        obj.each do |s|
          write(s)
        end
      end

      def printf(*args)
        write(sprintf(*args))
      end

      def puts(*obj)
        obj.each do |s|
          write(s)
          write($/)
        end
      end

      def close(*args)
        # close watcher before io closed
        io_watcher.close
        @obj.close
      end

      private

      def nonblock_eof?
        @readbuf.eof? && io_eof?
      end

      def io_eof?
        @eof
      end

      BUF_CHUNK_SIZE = 1024 * 16

      def fill_read_buf
        return true if @eof
        while (data = @obj.read_nonblock(BUF_CHUNK_SIZE, exception: false))
          case data
            when :wait_readable, :wait_writable
              # set eof to unknown(nil)
              @eof = nil
              return nil
            else
              # set eof to false
              @eof = false if @eof.nil?
              @readbuf.string << data
          end
        end
        # set eof to true
        @eof = true
      end
    end

    def set_encoding(*args)
      @readbuf.set_encoding(*args)
      super(*args)
    end

    def lineno
      @readbuf.lineno
    end

    def lineno= no
      @readbuf.lineno = no
    end

    def rewind
      # clear buf if seek offset is not zero
      unless @seek.zero?
        @seek = 0
        @readbuf.string.clear
      end
      @readbuf.rewind
    end

    def seek(*args)
      @readbuf.string.clear
      @seek = args[0]
      @obj.seek(*args)
    end

    prepend IOMethods
  end
end
