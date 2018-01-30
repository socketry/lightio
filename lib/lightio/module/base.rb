module LightIO::Module
  module Base
    module NewHelper
      protected
      def define_new_for_modules(*mods)
        mods.each {|mod| define_new_for_module(mod)}
      end

      def define_new_for_module(mod)
        LightIO::Module.send(:module_eval, <<-STR, __FILE__, __LINE__ + 1)
          module #{mod}
            module ClassMethods
              def new(*args, &blk)
                obj = LightIO::Library::#{mod}.__send__ :allocate
                obj.__send__ :initialize, *args, &blk
                obj
              end
            end
          end
        STR
      end
    end

    module Helper
      protected
      def wrap_to_library(obj)
        return _wrap(obj) if self.respond_to?(:_wrap)
        find_library_class._wrap(obj)
      end

      # private
      def find_library_class
        name = self.name
        namespace_index = name.rindex("::")
        class_name = namespace_index.nil? ? name : name[(namespace_index + 2)..-1]
        LightIO::Library.const_get(class_name)
      end
    end
  end
end