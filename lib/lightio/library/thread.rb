module LightIO::Library
  class Thread
    extend Forwardable

    RAW_THREAD = ::Thread

    def initialize(*args, &blk)
      init_core(*args, &blk)
    end

    def_delegators :@beam, :join, :alive?, :value

    def kill
      @beam.kill && self
    ensure
      Thread.send(:threads).delete(object_id)
    end

    alias exit kill
    alias terminate kill

    def status
      if Thread.current == self
        'run'
      else
        alive? ? 'sleep' : false
      end
    end

    def thread_variables
      thread_values.keys
    end

    def thread_variable_get(name)
      thread_values[name]
    end

    def thread_variable_set(name, value)
      thread_values[name.to_sym] = value
    end

    def [](name)
      fiber_values[name]
    end

    def []=(name, val)
      fiber_values[name] = val
    end

    def inspect
      "#<LightIO::Library::Thread:#{object_id} #{status}>"
    end

    private
    def init_core(*args, &blk)
      @beam = LightIO::Beam.new(*args, &blk)
      @beam.instance_variable_set(:@lightio_thread, self)
      # register this thread
      thread_values
      # remove thread and thread variables
      ObjectSpace.define_finalizer(self, self.class.finalizer(self.object_id))
    end

    def thread_values
      Thread.send(:threads)[object_id] ||= {}
    end

    def fibers_and_values
      @fibers_and_values ||= Hash.new {{}}
    end

    def fiber_values
      fibers_and_values[Fiber.current]
    end

    class << self
      extend Forwardable
      def_delegators :'LightIO::Library::Thread::RAW_THREAD', :DEBUG, :DEBUG=, :abort_on_exception, :abort_on_exception=

      def fork(*args, &blk)
        obj = allocate
        obj.send(:init_core, *args, &blk)
        obj
      end

      alias start fork

      def kill(thr)
        thr.kill
      end

      def current
        LightIO::Beam.current.instance_variable_get(:@lightio_thread) || main
      end

      # TODO implement
      def handle_interrupt()
        raise
      end

      # TODO implement
      def pending_interrupt
        raise
      end

      # TODO implement
      def exclusive
        raise
        yield
      end

      def list
        thread_list = []
        threads.keys.each {|id|
          begin
            thr = ObjectSpace._id2ref(id)
            unless thr.alive?
              # manually remove thr from threads
              thr.kill
              next
            end
            thread_list << thr
          rescue RangeError
            # mean object is recycled
            # just wait ruby GC call finalizer to remove it from threads
            next
          end
        }
        thread_list
      end

      def pass
        LightIO::Beam.pass
      end

      alias stop pass

      def finalizer(object_id)
        proc {threads.delete(object_id)}
      end

      private

      # TODO how to simulate main thread?
      def main
        raise
        @main_thread ||= Thread.new {}
      end

      # threads and threads variables
      def threads
        @threads ||= {}
      end
    end
  end
end
