# Mocks a tcp socket to an irc server
class IrcMockSocket
  # Creates a new mock socket
  #
  # @param [Address] The hostname or ip address of the server
  # @param [Port] The port number to connect to
  # @return [nil] Nil
  def initialize(address, port)
    @state = :init
  end

  # Writes data to the socket
  #
  # This particular method uses flipstates
  # to mock the data that comes back from the server
  # @param [Data] The data to send to the server
  # @return [nil] Nil
  def write(data)
    if data.match /NICK \w+\r\n/
      @state = :nick
    elsif @state == :nick && data.match(/USER \w+ [0-9]+ (\*|\w+) :\w+\r\n/)
      @state = :user
    end
  end

  # Reads a line from the socket
  #
  # @return [String] Data from the socket
  def gets
    return "PING :00293923823" if @state == :user
    return ''
  end

  # Reads all lines from the socket.
  #
  # @return [Array<String>] All the data from the socket
  def readlines
    return ["PING :00293923823"] if @state == :user
    return nil
  end

  # Closes the mock socket
  # @return [nil] Nil
  def close
    
  end

  # Gets the remote address structure for the mock socket
  #
  # @see Addrinfo
  # @return [IrcMockSocket] The IrcMockSocket fakes Addrinfo impl as well.
  def remote_address
    self
  end

  # Gets the current ip address of the mock socket.
  #
  # @return [String] Ip address of the mock socket.
  def ip_address
    '64.31.0.226'
  end

  # Gets the current port of the mock socket.
  #
  # @return [Fixnum] Port of the mock socket.
  def ip_port
    6667
  end 
end

