# This class represents an irc channel.
class Channel
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

  # Stores persistent data on the channel object.
  #
  # @param [Symbol, String] The key to this object.
  # @param [Object] Some object to store.
  # @return [nil] Nil
  def store(key, value)
    if @storage.nil?
      @storage = {}
    end
    @storage[key] = value
  end

  # Fetches persistent data on the channel object.
  #
  # @param [Symbol, String] The key to this object.
  # @return [Object] The object that was previously stored.
  def fetch(key)
    return nil if @storage.nil?
    return @storage[key]
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

