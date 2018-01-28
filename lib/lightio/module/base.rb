module LightIO::Module
  module Base
    module Helper
      protected
      def wrap_to_library(obj)
        return _wrap(obj) if self.respond_to?(:_wrap)
        find_library_class._wrap(obj)
      end

      private
      def find_library_class
        name = self.name
        s = name.rindex("::") + 2
        class_name = name[s..-1]
        LightIO::Library.const_get(class_name)
      end
    end
  end
end