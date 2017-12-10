require 'lightio/library/queue'
require 'lightio/library/kernel_ext'
require 'lightio/library/timeout'

module LightIO
  # Library include modules can cooperative with LightIO::Beam
  module Library
    # extend library modules
    def self.included(base)
      base.extend KernelExt
      base.extend Timeout
    end
  end
end