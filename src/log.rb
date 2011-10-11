# Provides logging for the bot.
class Log
  # Information, requires no attention, will not be prepended.
  Information = 0
  # Cautionary tale, prepended with "Warning: "
  Warning = 1
  # Critical failure, prepended with "Error: "
  Error = 2

  # Sets the log provider for the bot.
  #
  # @param [Object] Log provider. @see StdoutProvider for
  #   an idea on how to create a provider.
  def self.set_provider(provider)
    @@provider = provider
  end

  # Writes a message to the log with an optional
  # error message level.
  #
  # @param [String] The message to write.
  # @param [Fixnum] The log level @see Log
  # @return [nil] Nil
  def self.write(msg, level = Log::Information)
    raise StandardError, 'Provider must not be nil.' if @@provider == nil
    case level
    when Log::Warning
      msg = 'Warning: ' + msg
    when Log::Error
      msg = 'Error: ' + msg
    end
    @@provider.write(msg, level)
  end
end

