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
  # @param [true, Fixnum] The port of the irc server, defaults to 6667
  # @return [nil] Nil
  def initialize(address, port = 6667)
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
    data.each do |d|
      @socket.write(d + "\r\n")
    end
  end

  # Returns a single line from the server
  #
  # @return [String] A single line from the server
  def read
    return @socket.gets.chomp
  end

  # Returns all the lines possible in the buffer
  #
  # @return [Array<String>] Each line from the buffer
  def readlines
    lines = @socket.readlines
    lines.each_index do |i|
      lines[i].chomp!
    end
    return lines
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

