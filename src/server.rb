require_relative 'irc_socket_factory.rb'

class Server
  class State
    Fresh = :fresh
    Connected = :connected
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
    return @socket.read
  end

  def state?
    return @state
  end

  attr_reader :address
  attr_reader :port
end
