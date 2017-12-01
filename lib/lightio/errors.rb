module LightIO
  class Error < RuntimeError
  end

  class TimeoutError < Error
  end

  class InvalidTransferError < Error
  end
end