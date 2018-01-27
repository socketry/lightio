module LightIO::Module
  module Base
    module ClassMethods
      def prepended(mod)
        if (class_methods_module = mod.const_get(:ClassMethods) rescue nil)
          mod.singleton_class.prepend(class_methods_module)
        end
      end
    end

    def self.included(base)
      base.send :extend, ClassMethods
    end
  end
end