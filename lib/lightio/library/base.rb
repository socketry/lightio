module LightIO::Library
  module Base
    module MockMethods
      protected
      def mock(klass)
        @mock_klass = klass
        define_alias_methods
        define_method_missing(singleton_class, @mock_klass)
        define_instance_method_missing(self, :@obj)
        define_mock_methods
        extend_class_methods
      end

      attr_reader :mock_klass

      private

      def define_alias_methods
        class_methods_module = LightIO::Module.const_get("#{mock_klass}::ClassMethods") rescue nil
        return unless class_methods_module
        methods = class_methods_module.instance_methods(false).select {|method| mock_klass.respond_to?(method)}
        methods.each do |method|
          origin_method_name = "origin_#{method}"
          mock_klass.singleton_class.__send__(:alias_method, origin_method_name, method)
          mock_klass.singleton_class.__send__(:protected, origin_method_name)
        end
      end

      def define_method_missing(base, target_var)
        base.send(:define_method, :method_missing) {|*args| target_var.__send__(*args)}
        base.send(:define_method, :respond_to_missing?) {|method, *| target_var.respond_to?(method)}
      end

      def define_instance_method_missing(base, target_var)
        base.send(:define_method, :method_missing) {|*args| instance_variable_get(target_var).__send__(*args)}
        base.send(:define_method, :respond_to_missing?) {|method, *| instance_variable_get(target_var).respond_to?(method)}
      end

      def define_mock_methods
        define_method :is_a? do |klass|
          mock_klass = self.class.__send__(:call_method_from_ancestors, :mock_klass)
          return super(klass) unless mock_klass
          mock_klass <= klass || super(klass)
        end

        alias_method :kind_of?, :is_a?

        define_method :instance_of? do |klass|
          mock_klass = self.class.__send__(:mock_klass)
          return super(klass) unless mock_klass
          mock_klass == klass || super(klass)
        end
      end

      def call_method_from_ancestors(method)
        __send__(method) || begin
          self.ancestors.each do |klass|
            result = klass.__send__(method)
            break result if result
          end
        end
      end

      def extend_class_methods
        class_methods_module = LightIO::Module.const_get("#{mock_klass}::ClassMethods")
        self.__send__ :extend, class_methods_module
      rescue NameError
        nil
      end
    end

    module ClassMethods
      def _wrap(obj)
        if obj.instance_of? self
          obj
        else
          mock_obj = allocate
          mock_obj.instance_variable_set(:@obj, obj)
          mock_obj
        end
      end
    end

    def initialize(*args)
      obj = self.class.send(:call_method_from_ancestors, :mock_klass).send(:origin_new, *args)
      @obj = obj
    end

    class << self
      def included(base)
        base.send :extend, MockMethods
        base.send :extend, ClassMethods
      end
    end
  end
end