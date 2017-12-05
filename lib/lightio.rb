# LightIO
require 'lightio/version'
require 'lightio/errors'
require 'lightio/core'
require 'lightio/watchers'
require 'lightio/library'

module LightIO
  include Core
  include Library
end
