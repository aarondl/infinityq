require_relative 'irc_mock_protocol_file'

# The IrcProtocolFileFactory class, retrieves
# an appropriate class to test with.
class IrcProtocolFileFactory
  # Gets a file object or a mock object from which to read
  # the protocol
  #
  # @param [String] The path to the file to open
  # @return [File, IrcMockProtocolFile] One of the two depending on environment
  def self.get_file(filename)
    if ENV['INF_ENV'] == 'TEST'
      return IrcMockProtocolFile.new()
    else
      return File.new(filename, 'r')
    end
  end
end

