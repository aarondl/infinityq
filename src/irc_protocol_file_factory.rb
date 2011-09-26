require_relative 'irc_mock_protocol_file.rb'

class IrcProtocolFileFactory
  def self.get_file(filename)
    if ENV['RBB_ENV'] == 'TEST'
      return IrcMockProtocolFile.new()
    else
      return File.new(filename, 'r')
    end
  end
end
