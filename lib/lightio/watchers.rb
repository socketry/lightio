require_relative 'watchers/watcher'
require_relative 'watchers/timer'
require_relative 'watchers/schedule'
require_relative 'watchers/io'

# Watcher is a abstract struct, for libraries to interact with ioloop
# see IOloop#wait method
module LightIO::Watchers
end