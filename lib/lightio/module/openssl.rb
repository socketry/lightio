module LightIO::Module
  extend Base::NewHelper

  module OpenSSL
    module SSL
      module SSLSocket
      end
    end
  end

  define_new_for_module 'OpenSSL::SSL::SSLSocket'
end
