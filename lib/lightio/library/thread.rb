module LightIO::Library
  class Thread
    RAW_THREAD = ::Thread


    module FallbackHelper
      module ClassMethods
        def fallback_method(obj, method, warning_text)
          define_method method do |*args|
            warn warning_text
            obj.public_send method, *args
          end
        end

        def fallback_thread_class_methods(*methods)
          methods.each {|m| fallback_method(RAW_THREAD.main, m, "This method is fallback to native Thread class,"\
                                                   " it may cause unexpected behaviour,"\
                                                   " open issues on https://github.com/socketry/lightio/issues"\
                                                   " if this behaviour not approach you purpose")}
        end
      end

      include ClassMethods

      def fallback_main_thread_methods(*methods)
        methods.each {|m| fallback_method(main, m, "This method is fallback to native main thread,"\
                                                   " it may cause unexpected behaviour,"\
                                                   " open issues on https://github.com/socketry/lightio/issues"\
                                                   " if this behaviour not approach you purpose")}
      end

      def self.included(base)
        base.send :extend, ClassMethods
      end
    end

    class << self
      extend Forwardable
      def_delegators :'LightIO::Library::Thread::RAW_THREAD', :DEBUG, :DEBUG=

      include FallbackHelper
      fallback_thread_class_methods :abort_on_exception, :abort_on_exception=

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
        raise LightIO::Error, "Can't find current thread from fiber #{beam_of_fiber.inspect},"\
                              "current Thread implementation can't find Thread from Fiber or Beam execution scope,"\
                              "please open issues on https://github.com/socketry/lightio/issues"\
                              " if you really need this feature"
      end

      # TODO implement
      def exclusive
        raise "not implement"
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

    extend Forwardable

    def initialize(*args, &blk)
      init_core(*args, &blk)
    end

    def_delegators :@beam, :alive?, :value

    fallback_main_thread_methods :abort_on_exception,
                                 :abort_on_exception=,
                                 :handle_interrupt,
                                 :pending_interrupt,
                                 :add_trace_func,
                                 :backtrace,
                                 :backtrace_locations,
                                 :priority,
                                 :priority=,
                                 :safe_level

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
      elsif alive?
        @beam.error.nil? ? 'sleep' : 'abouting'
      else
        @beam.error.nil? ? false : nil
      end
    end

    def thread_variables
      thread_values.keys
    end

    def thread_variable_get(name)
      thread_values[name.to_sym]
    end

    def thread_variable_set(name, value)
      thread_values[name.to_sym] = value
    end

    def thread_variable?(key)
      thread_values.key?(key)
    end

    def [](name)
      fiber_values[name.to_sym]
    end

    def []=(name, val)
      fiber_values[name.to_sym] = val
    end

    #TODO
    def group

    end

    def inspect
      "#<LightIO::Library::Thread:0x00#{object_id.to_s(16)} #{status}>"
    end

    def join(limit=nil)
      @beam.join(limit) && self
    end

    def key?(sym)
      fiber_values.has_key?(sym)
    end

    def keys
      fiber_values.keys
    end

    def raise(exception, message=nil, backtrace=nil)
      @beam.raise(LightIO::Beam::BeamError.new(exception), message, backtrace)
    end

    def run
      Thread.pass
    end

    alias wakeup run

    def stop?
      !alive? || status == 'sleep'
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
  end
end
