require_relative 'library/queue'
require_relative 'library/kernel_ext'
require_relative 'library/timeout'
require_relative 'library/io'
require_relative 'library/socket'
require_relative 'library/thread'
require_relative 'library/threads_wait'

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