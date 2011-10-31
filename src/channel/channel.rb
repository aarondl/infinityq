require_relative '../store'

# This class represents an irc channel.
class Channel < Store
  # Creates a new channel with a name.
  #
  # @param [Symbol] The server key.
  # @param [String] The name of the channel.
  # @param [Bool] Whether or not this is a state only object.
  # @return [Channel] A new channel.
  def initialize(server_key, name, stateonly = true)
    @server_key = server_key
    @name = name.downcase
    @users = {}
    @nicks = {}
    @stateonly = stateonly
  end

  # Adds a user to the channel.
  #
  # @param [User] The user to add.
  # @return [nil] Nil
  def add_user(user)
    server_user = user[@server_key]
    throw StandardError, 'How did this happen?' if server_user.nil?
    @users[server_user.fullhost] = user
    @nicks[server_user.nick] = user
  end

  # Looks up a user by nick or by host.
  #
  # @param [String] A string identifying the user.
  # @return [User] A user object.
  def [](lookup)
    if lookup.include?('@')
      return @users[lookup]
    else
      return @nicks[lookup]
    end
  end

  attr_reader :name
  attr_reader :server_key
  attr_accessor :stateonly
end

