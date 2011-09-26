require_relative 'resolver_factory.rb'
require_relative 'irc_socket_factory.rb'

class IrcServer
  class State
    Fresh = :fresh
    Connected = :connected
    Disconnected = :disconnected
  end

  def initialize(address, port = 6667)
    @address = address
    @port = port
    @state = State::Fresh
  end

  def connect
    @socket = IrcSocketFactory.get_socket(@address, @port)
    @state = State::Connected
  end

  def write(*data)
    data.each do |d|
      @socket.write(d + "\r\n")
    end
  end

  def read
    return @socket.gets.chomp
  end

  def readlines
    lines = @socket.readlines
    lines.each_index do |i|
      lines[i].chomp!
    end
    return lines
  end

  def disconnect
    @socket.close if @state == State::Connected
    @state = State::Disconnected
  end

  def state?
    @state
  end

  def ip?
    @socket.remote_address.ip_address
  end

  def port?
    @socket.remote_address.ip_port
  end

  def address?
    @address
  end

  def hostname?
    ResolverFactory.resolve ip?
  end

end

