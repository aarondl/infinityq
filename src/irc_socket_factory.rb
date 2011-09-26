require_relative 'irc_mock_socket'

# IrcSocketFactory, gets a real socket or a mock
# depending on environment.
class IrcSocketFactory
  # Gets a socket depending on the environment
  #
  # @param [String] The hostname or ip to connect to
  # @param [Fixnum] The port to connect to
  # @return [IrcMockSocket, TCPSocket] Either or depending on environment
  def self.get_socket(address, port)
    return ENV['RBB_ENV'] == 'TEST' ? 
      IrcMockSocket.new(address, port) : 
      TCPSocket.new(address, port)
  end
end

