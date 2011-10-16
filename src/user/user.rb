require_relative 'access'

# This class represents an irc user.
class User
  # Stores server state and access information about
  # a user.
  class ServerUser
    # Creates a server user with optional access.
    #
    # @param [Symbol] The servers key.
    # @param [Access] Access for the user.
    # @return [ServerUser] The new server user.
    def initialize(key, access = nil)
      @server_key = key
      @access = access || Access.new
      @channels = {}
    end

    # Adds a channel with optional access to
    # the server.
    #
    # @param [Symbol] Channel key.
    # @param [Fixnum] The power of this user.
    # @param [Array<Fixnum>] The flags for this user.
    # @return [nil] Nil
    def add_channel(channel_key, power = 0, *flags)
      access = nil
      if power != 0 || flags.length != 0
        access = Access.new(power, *flags)
      end
      @channels[channel_key] = ChannelUser.new(channel_key, access)
    end

    # Gets the ChannelUser object for this channel name.
    #
    # @param [String] Channel name.
    # @return [ChannelUser] ChannelUser object.
    def [](channel_name)
      return @channels[channel_name]
    end
      
    attr_reader :access
    attr_reader :server_key
  end

  # Stores channel state and access information about
  # a user.
  class ChannelUser
    # Creates a channel user with optional access.
    #
    # @param [String] The channel name.
    # @param [Access] Access for the user.
    # @return [ChannelUser] The new channel user.
    def initialize(key, access = nil)
      @channel_name = key
      @access = access || Access.new
    end

    attr_reader :access
    attr_reader :channel_name
  end

  # Creates a new user with no global access
  # and and empty hosts array.
  #
  # @return [User] A new user object.
  def initialize
    @hosts = []
    @servers = {}
    @global_access = Access.new
  end
  
  # Adds a host to the collection.
  #
  # @param [String] The host to add.
  def add_host(host)
    unless @hosts.include?(host)
      @hosts << host
    end
  end

  # Iterates through all the hosts.
  #
  # @param [Block] To iterate through each host.
  # @return [nil] Nil
  def each_host(&blk)
    @hosts.each do |host|
      yield host
    end
  end

  # Adds a server with optional access to
  # the user.
  #
  # @param [Symbol] Server key.
  # @param [Fixnum] The power of this user.
  # @param [Array<Fixnum>] The flags for this user.
  # @return [nil] Nil
  def add_server(server_key, power = 0, *flags)
    access = nil
    if power != 0 || flags.length != 0
      access = Access.new(power, *flags)
    end
    @servers[server_key] = ServerUser.new(server_key, access)
  end

  # Gets a ServerUser object from the user.
  #
  # @param [Symbol] The key of the server to look up.
  # @return [ServerUser] The server user object.
  def [](key)
    return @servers[key]
  end

  # Sets the context for the access method.
  # Call with no arguments to reset to global.
  #
  # @param [Symbol] Server key.
  # @param [String] Channel name.
  # @return [nil] Nil
  def set_context(server_key = nil, channel_name = nil)
    if server_key != nil && self[server_key].nil?
      raise StandardError, 'Bad context'
    end
    if channel_name != nil && self[server_key][channel_name].nil?
      raise StandardError, 'Bad context'
    end
    @context_server = server_key
    @context_channel = channel_name
  end

  # Gets the access object based on the context.
  #
  # @return [Access] An access object.
  def access
    global = @global_access
    server = nil
    channel = nil
    if @context_server != nil
      server = self[@context_server].access

      if @context_channel != nil
        channel = self[@context_server][@context_channel].access
      end
    end

    return global if server.nil? && channel.nil?
    return Access::merge(global, server, channel)
  end

  # Returns the number of hosts.
  #
  # @return [Fixnum] The number of hosts.
  def hosts_count
    return @hosts.length
  end

  attr_reader :global_access
end

