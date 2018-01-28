module LightIO::Library
  module Base
    module MockMethods
      protected
      def mock(klass)
        @mock_klass = klass
        define_mock_methods
        extend_class_methods
      end

      attr_reader :mock_klass

      private

      def define_mock_methods
        define_method :is_a? do |klass|
          self.class.__send__(:mock_klass) <= klass || super(klass)
        end

        alias_method :kind_of?, :is_a?

        define_method :instance_of? do |klass|
          self.class.__send__(:mock_klass) == klass || super(klass)
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
      def new(*args)
        obj = mock_klass.new(*args)
        _wrap(obj)
      end

      def _wrap(obj)
        if obj.is_a? self
          obj
        else
          mock_obj = allocate
          mock_obj.__send__(:initialize, obj)
          mock_obj
        end
      end
    end

    def initialize(obj)
      @obj = obj
    end

    class << self
      def included(base)
        base.send :extend, MockMethods
        base.send :extend, ClassMethods
        define_method_missing(base, :@obj)
        define_method_missing(base.singleton_class, :@mock_klass)
      end

      private
      def define_method_missing(base, target_var)
        base.send(:define_method, :method_missing) {|*args| instance_variable_get(target_var).__send__(*args)}
        base.send(:define_method, :respond_to?) {|*args| instance_variable_get(target_var).respond_to?(*args)}
        base.send(:define_method, :respond_to_missing?) {|method, *| instance_variable_get(target_var).respond_to?(method)}
      end
    end
  end
end