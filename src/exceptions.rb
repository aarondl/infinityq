class Bot
  # Raised when a configuration error has occurred
  class ConfigError < StandardError
  end
end

class IrcProtocol
  # Raised when a Protocol parsing error has occurred
  class ProtocolFormatError < StandardError
  end
end

