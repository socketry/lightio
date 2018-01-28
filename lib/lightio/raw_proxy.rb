# helper for access raw ruby object methods
# use it to avoid monkey patch affect

module LightIO
  class RawProxy
    def initialize(klass, methods: [], instance_methods: [])
      @klass = klass
      @methods = methods.map {|method| [method.to_sym, klass.method(method)]}.to_h
      @instance_methods = instance_methods.map {|method| [method.to_sym, klass.instance_method(method)]}.to_h
    end

    def send(method, *args)
      method = method.to_sym
      return method_missing(method, *args) unless @methods.key?(method)
      @methods[method].call(*args)
    end

    def instance_send(instance, method, *args)
      method = method.to_sym
      return method_missing(method, *args) unless @instance_methods.key?(method)
      @instance_methods[method].bind(instance).call(*args)
    end
  end
end