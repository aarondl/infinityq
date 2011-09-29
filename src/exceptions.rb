class Bot
  # Raised when a configuration error has occurred
  class ConfigError < StandardError
  end
end

class IrcProtoEvent
  # Raised when a Protocol parsing error has occurred
  class ProtocolFormatError < StandardError
  end
  class ProtocolParseError < StandardError
  end
end

