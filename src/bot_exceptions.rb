class Bot
  class ConfigError < RuntimeError
    attr_reader :message
    def initialize(msg)
      @message = msg
    end
  end
end

