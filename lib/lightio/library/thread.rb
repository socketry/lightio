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
      fiber_values[name.to_sym] = val
    end

    def inspect
      "#<LightIO::Library::Thread:0x00#{object_id.to_s(16)} #{status}>"
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
      raise ThreadError unless alive?
      Thread.send(:threads)[object_id] ||= {}
    end

    def fibers_and_values
      @fibers_and_values ||= {}
    end

    def fiber_values
      beam_or_fiber = LightIO::Beam.current
      # ignore LightIO::Thread fiber, Beam fiber, root fiber
      if beam_or_fiber.is_a?(LightIO::Beam) ||
        beam_or_fiber.instance_variable_defined?(:@lightio_thread) ||
        LightIO::Core::LightFiber.is_root?(beam_or_fiber)
        beam_or_fiber = @beam
      end
      fibers_and_values[beam_or_fiber] ||= {}
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
        beam_of_fiber = LightIO::Beam.current
        thr = beam_of_fiber.instance_variable_get(:@lightio_thread)
        return thr if thr
        return main if LightIO::Core::LightFiber.is_root?(beam_of_fiber)
        raise LightIO::Error, "Can't find current thread from fiber #{beam_of_fiber.inspect},
current Thread implementation can't find Thread from Fiber or Beam execution scope,
please open issues if you really need this feature"
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

      def main
        RAW_THREAD.main
      end
      private

      # threads and threads variables
      def threads
        @threads ||= {}
      end
    end
  end
end
