module LightIO::Module
  module Base
    class << self
      def find_library_class(klass)
        return LightIO::Library::Base.send(:nameless_classes)[klass] if klass.name.nil?
        name = klass.name
        begin
          LightIO::Library.const_get(name)
        rescue NameError
          # retry without namespace
          namespace_index = name.rindex("::")
          raise if namespace_index.nil?
          class_name = name[(namespace_index + 2)..-1]
          LightIO::Library.const_get(class_name)
        end
      end
    end

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

      def find_library_class
        Base.find_library_class(self)
      end
    end
  end
end