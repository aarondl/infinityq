require_relative 'log'

# This class is a provider for the logging facility.
# It provides logging facilities for stdout.
class StdoutProvider
  # Writes a message to stdout.
  #
  # @param [String] Message to write to stdout.
  # @param [Fixnum] The importance level of the log.
  # @return [nil] Nil
  def write(msg, level)
    if level >= Log::Error
      $stderr.puts msg
    else
      puts msg
    end
  end
end
