require 'lightio/version'
require 'lightio/errors'
require 'lightio/light_fiber'
require 'lightio/future'
require 'lightio/ioloop'
require 'lightio/watchers'
require 'lightio/backend/nio'
require 'lightio/beam'
require 'lightio/timeout'
require 'lightio/queue'
require 'lightio/kernel_ext'
require 'lightio/io_primitive'

module LightIO
  extend KernelExt
  extend IOPrimitive
  extend Timeout
end
