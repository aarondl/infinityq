require_relative 'irc_mock_socket'

class IrcSocketFactory
  def self.get_socket(address, port)
    return ENV['RBB_ENV'] == 'TEST' ? 
      IrcMockSocket.new(address, port) : 
      TCPSocket.new(address, port)
  end
end
