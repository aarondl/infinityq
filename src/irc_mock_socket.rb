# Mocks a tcp socket to an irc server
class IrcMockSocket
  # Some fake messages to pump out in order.
  Messages = [
    "PING :00293923",
    "832\r\n",
    ":irc.gamesurge.net NOTICE botname :how are you?\r\n:irc",
    ".gamesurge.net NOTICE botname ::D\r\n:irc.gamesurge.net NO",
    "TICE botname :here's some fun!\r\n",
    ":irc.gamesurge.net NOTICE botname :more fun for you!\r\n"
  ]

  # Creates a new mock socket
  #
  # @param [Address] The hostname or ip address of the server
  # @param [Port] The port number to connect to
  # @return [nil] Nil
  def initialize(address, port)
    @state = 0
  end

  # Writes data to the socket
  #
  # This particular method uses flipstates
  # to mock the data that comes back from the server
  # @param [Data] The data to send to the server
  # @return [nil] Nil
  def write(data)
    if @state == :quit
      return data.length / 2
    end
    if data.match(/NICK \w+\r\n/)
      @state = :nick
    elsif @state == :nick && data.match(/USER \w+ [0-9]+ (\*|\w+) :\w+\r\n/)
      @state = :user
    elsif data.match(/^QUIT/)
      @state = :quit
    end
    return data.length
  end

  # Reads a line from the socket
  #
  # @param [Fixnum] Maxbytes to read from the socket (ignored).
  # @return [String] Data from the socket
  def recv(max_bytes)
    if @state == :quit
      return nil
    elsif @state == :user
      @state = 0
    end
    if @state.kind_of?(Integer)
      msg = Messages[@state]
      @state += 1
      return msg
    end
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

