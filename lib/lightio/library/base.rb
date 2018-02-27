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
        define_inherited
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

      def define_inherited
        mock_klass.define_singleton_method(:inherited) do |klass|
          super(klass)
          library_super_class = LightIO::Module::Base.find_library_class(self)
          library_klass = Class.new(library_super_class) do
            include LightIO::Library::Base
            mock klass
          end
          if klass.name
            LightIO::Library::Base.send(:full_const_set, LightIO::Library, klass.name, library_klass)
          else
            LightIO::Library::Base.send(:nameless_classes)[klass] = library_klass
          end
          klass.define_singleton_method :new do |*args, &blk|
            obj = library_klass.__send__ :allocate
            obj.__send__ :initialize, *args, &blk
            obj
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
          mock_obj.__send__(:call_lightio_initialize)
          mock_obj
        end
      end
    end

    def initialize(*args)
      obj = self.class.send(:call_method_from_ancestors, :mock_klass).send(:origin_new, *args)
      @obj = obj
      call_lightio_initialize
      @obj
    end

    private
    def call_lightio_initialize
      __send__(:lightio_initialize) if respond_to?(:lightio_initialize, true)
    end

    def light_io_raw_obj
      @obj
    end

    class << self
      def included(base)
        base.send :extend, MockMethods
        base.send :extend, ClassMethods
      end

      private
      def nameless_classes
        @nick_classes ||= {}
      end

      def full_const_set(base, mod_name, const)
        mods = mod_name.split("::")
        mod_name = mods.pop
        full_mod_name = base.to_s
        mods.each do |mod|
          parent_mod = Object.const_get(full_mod_name)
          parent_mod.const_get(mod) && next rescue nil
          parent_mod.const_set(mod, Module.new)
          full_mod_name = "#{full_mod_name}::#{mod}"
        end
        Object.const_get(full_mod_name).const_set(mod_name, const)
      end
    end
  end
end