require 'thread'
require_relative 'queue'

module LightIO::Library
  class ThreadGroup
    include Base
    mock ::ThreadGroup
    prepend LightIO::Module::ThreadGroup

    Default = ThreadGroup._wrap(::ThreadGroup::Default)
  end


  class Thread
    prepend LightIO::Module::Thread

    # constants
    ThreadError = ::ThreadError
    Queue = LightIO::Library::Queue
    Backtrace = ::Thread::Backtrace
    SizedQueue = LightIO::Library::SizedQueue

    class Mutex
      prepend LightIO::Module::Mutex
    end

    class ConditionVariable
      prepend LightIO::Module::ConditionVariable
    end
  end

  Mutex = Thread::Mutex
  ConditionVariable = Thread::ConditionVariable
end
