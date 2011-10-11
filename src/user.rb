# This class represents an irc user.
class User
  # Initializes a user.
  #
  # @param [String] Nickname
  # @param [String] Host
  # @return [User] The newly created user object
  def initialize(nick, host)
    @nick = nick
    @host = host
  end

  # Returns nickname.
  def user
    @nick
  end

  attr_reader :nick, :host
end


