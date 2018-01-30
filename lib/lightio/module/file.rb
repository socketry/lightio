module LightIO::Module
  extend Base::NewHelper

  define_new_for_module "File"
  module File
    include Base
    module ClassMethods
    end
  end
end
