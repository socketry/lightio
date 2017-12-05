# Watcher is a abstract struct, for libraries to interact with ioloop
# see IOloop#wait method
require 'lightio/watchers/watcher'
require 'lightio/watchers/timer'
require 'lightio/watchers/schedule'
require 'lightio/watchers/io'

module LightIO::Watchers
end