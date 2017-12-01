module LightIO
  class Error < RuntimeError
  end

  class TimeoutError < Error
  end
end