require 'thread'

module LightIO::Module
  extend Base::NewHelper

  define_new_for_modules *%w{ThreadGroup Mutex Queue SizedQueue ConditionVariable}

  module Thread
    include LightIO::Module::Base

    module ClassMethods
      extend Forwardable

      def new(*args, &blk)
        obj = LightIO::Library::Thread.__send__ :allocate
        obj.__send__ :initialize, *args, &blk
        obj
      end

      def fork(*args, &blk)
        obj = LightIO::Library::Thread.__send__ :allocate
        obj.send(:init_core, *args, &blk)
        obj
      end

      alias start fork

      def kill(thr)
        thr.kill
      end

      def current
        return main if LightIO::Core::LightFiber.is_root?(Fiber.current)
        LightIO::Library::Thread.instance_variable_get(:@current_thread) || origin_current
      end

      def exclusive(&blk)
        LightIO::Library::Thread.__send__(:thread_mutex).synchronize(&blk)
      end

      def list
        thread_list = []
        LightIO::Library::Thread.__send__(:threads).keys.each {|id|
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
        proc {LightIO::Library::Thread.__send__(:threads).delete(object_id)}
      end

      def main
        origin_main
      end
    end
  end
end
