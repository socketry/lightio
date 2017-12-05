# LightIO
require 'lightio/version'
require 'lightio/errors'
require 'lightio/core'
require 'lightio/watchers'
require 'lightio/library'

# LightIO provide light-weight executor: LightIO::Beam and batch io operations,
# view LightIO::Core::Beam for Beam usage, view LightIO::Library::IOPrimitive to learn io primitives,
# main modules are included under LightIO namespace, so you can use LightIO::Beam or LightIO.wait_read(x) for convenient
module LightIO
  include Core
  include Library
end
