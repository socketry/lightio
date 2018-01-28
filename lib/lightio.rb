# LightIO
require 'lightio/version'
require 'lightio/errors'
require 'lightio/raw_proxy'
require 'lightio/core'
require 'lightio/watchers'
require 'lightio/wrap'
require 'lightio/module'
require 'lightio/library'
require 'lightio/monkey'

# LightIO provide light-weight executor: LightIO::Beam and batch io libraries,
# view LightIO::Core::Beam to learn how to concurrent programming with Beam,
# view LightIO::Watchers::IO to learn how to manage 'raw' io objects,
# Core and Library modules are included under LightIO namespace, so you can use LightIO::Beam for convenient
module LightIO
  include Core
  include Library
end
