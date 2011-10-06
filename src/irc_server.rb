require_relative 'resolver_factory'
require_relative 'irc_socket_factory'

# The IrcServer class, this class
# is responsible for sending and recieving data
# to and from the Irc Server
class IrcServer
  # The state of the IrcServer
  class State
    # Initialized, not used
    Fresh = :fresh
    # Connected
    Connected = :connected
    # Disconnected
    Disconnected = :disconnected
  end

  # Creates a fresh IrcServer
  #
  # @param [String] The address of the irc server
  # @param [Fixnum] The port of the irc server, defaults to 6667
  # @return [nil] Nil
  def initialize(address, port = 6667)
    port = 6667 if port == nil
    @address = address
    @port = port
    @state = State::Fresh
  end

  # Connects to the configured irc server
  def connect
    @socket = IrcSocketFactory.get_socket(@address, @port)
    @state = State::Connected
  end

  # Writes data to the irc server
  #
  # @param [Array] Data chunks to send to the server
  # @return [nil] Nil
  def write(*data)
    unless @state == State::Connected
      raise IOError, 'Socket must be connected to write'
    end
    data.each do |d|
      n = @socket.write(d + "\r\n")
      if n != d.length + 2
        raise IOError, "Socket write didn't complete."
      end
    end
  end

  # Returns as many lines as possible from the server.
  # Will block if there's nothing to read.
  #
  # @return [Array<String>] An array of irc protocol messages.
  def read
    unless @state == State::Connected
      raise IOError, 'Socket must be connected to read'
    end

    ret = nil
    truncated = nil

    loop do
      msg = @socket.recv(8192)
      if msg == nil || msg.empty?
        @state = State::Disconnected
        return nil
      end

      split = msg.split("\r\n")
      
      if msg.end_with?("\r\n")
        if truncated
          ret.push truncated + split[0]
          ret.push split[1...split.length]
          return ret
        end
        return split
      end

      if truncated
        ret.push truncated + split[0]
        ret.push split[1...split.length-1]
      else
        ret = split[0...split.length-1]
      end
      truncated = split[split.length-1]
    end
  end

  # Disconnects from the irc server
  # @return [nil] Nil
  def disconnect
    @socket.close if @state == State::Connected
    @state = State::Disconnected
  end

  # Gets the state of the server
  #
  # @return [IrcServer::State] One of the IrcServer::State constants.
  def state?
    @state
  end

  # Gets the ip address of the connection
  #
  # @return [String] The ip address of the connection, may not be what was passed to the constructor
  def ip?
    @socket.remote_address.ip_address
  end

  # Gets the port of the connection
  #
  # @return [Fixnum] The port of the connection
  def port?
    @socket.remote_address.ip_port
  end

  # Gets the address of the connection
  #
  # @return [String] This is the address that was passed into the constructor.
  def address?
    @address
  end

  # Gets the hostname of the ip address we're connected to
  #
  # @return [String] The hostname of the current server, uses reverse dns lookup.
  def hostname?
    ResolverFactory.resolve ip?
  end

end

