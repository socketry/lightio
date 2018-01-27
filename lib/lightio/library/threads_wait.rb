require 'thwait'

module LightIO::Library
  class ThreadsWait
    ErrNoWaitingThread = ::ThreadsWait::ErrNoWaitingThread
    ErrNoFinishedThread = ::ThreadsWait::ErrNoFinishedThread

    prepend LightIO::Module::ThreadsWait
  end
end
