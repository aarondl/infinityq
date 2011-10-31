require_relative 'access'
require_relative '../store'

# Stores server state and access information about
# a user.
class ServerUser < Store
  # Creates a server user with optional access.
  #
  # @param [Symbol] The servers key.
  # @param [Bool] If this server user is only for state keeping.
  # @param [Access] Access for the user.
  # @return [ServerUser] The new server user.
  def initialize(key, stateonly = true, access = nil)
    @server_key = key
    @stateonly = stateonly
    @access = access || Access.new
    @channels = {}
  end

  # Sets the state for the server.
  #
  # @param [String] Host
  # @param [String] Realname
  # @param [Array<String>] A list of channel keys.
  # @return [nil] Nil
  def set_state(host, realname = nil, channels = nil)
    self.fullhost = host
    @realname = realname
    unless channels.nil?
      for i in (0...channels.length)
        channels[i] = channels[i].downcase
        unless @channels.has_key?(channels[i])
          add_channel(channels[i])
        end
      end
    end
    @chanlist = channels
    @online = true
  end

  # Wipes the state.
  #
  # @return [nil] Nil
  def wipe_state
    @fullhost = @host = @nick = @realname = @chanlist = nil
    @online = false

    new_channels = {}
    @channels.each do |name, channel|
      unless channel.stateonly
        channel.wipe_state
        new_channels[name] = channel
      end
    end
    @channels = new_channels
  end

  # Adds a channel with optional access to
  # the server.
  #
  # @param [String] Channel name.
  # @param [Bool] If this channel is kept for state only.
  # @param [Fixnum] The power of this user.
  # @param [Array<Fixnum>] The flags for this user.
  # @return [nil] Nil
  def add_channel(channel_name, stateonly = true, power = 0, *flags)
    access = nil
    channel_name = channel_name.downcase
    if power != 0 || flags.length != 0
      access = Access.new(power, *flags)
    end
    @channels[channel_name] = ChannelUser.new(channel_name, stateonly, access)
  end

  # Removes the channel from the server.
  #
  # @param [String] Channel name.
  # @return [nil] Nil
  def remove_channel(channel_name)
    @channels.delete(channel_name.downcase)
  end

  # Gets the ChannelUser object for this channel name.
  #
  # @param [String] Channel name.
  # @return [ChannelUser] ChannelUser object.
  def [](channel_name)
    return @channels[channel_name.downcase]
  end

  # Gets the current channel names.
  #
  # @return [Array<String>] The channel names.
  def channels
    return @chanlist
  end

  # Checks to see if this user is online.
  #
  # @return [Bool] Whether or not they're online.
  def online?
    return @online
  end

  attr_reader :fullhost
  attr_reader :host
  attr_reader :nick
  attr_reader :realname
    
  attr_reader :access
  attr_reader :server_key

  attr_accessor :stateonly

  private
  def fullhost=(value)
    @fullhost = value
    split = value.split('@')
    if split[0].start_with?('~')
      split[0] = split[0][1...split[0].length]
    end
    @nick = split[0]
    @host = split[1]
  end
end

# Stores channel state and access information about
# a user.
class ChannelUser < Store
  # Creates a channel user with optional access.
  #
  # @param [String] The channel name.
  # @param [Bool] If this channel user is for state only.
  # @param [Access] Access for the user.
  # @return [ChannelUser] The new channel user.
  def initialize(key, stateonly = true, access = nil)
    @channel_name = key
    @stateonly = stateonly
    @access = access || Access.new
  end

  # Sets the state for the channel.
  #
  # @param [String] Modes
  # @return [nil] Nil
  def set_state(modes = nil)
    @modes = modes
    @online = true
  end

  # Checks to see if the user has a mode.
  #
  # @param [String] The mode to check for.
  # @return [Bool] If the mode was found.
  def has_mode?(mode)
    return @modes.include?(mode)
  end

  # Wipes the state for the channel.
  #
  # @return [nil] Nil
  def wipe_state
    @modes = nil
    @online = false
  end

  # Iterates through the modes.
  #
  # @param [Block] A block to handle each mode.
  # @return [nil] Nil
  def each_mode(&blk)
    @modes.each_char do |c|
      yield c
    end
  end

  # Checks to see if this user is online.
  #
  # @return [Bool] Whether or not they're online.
  def online?
    return @online
  end

  attr_reader :access
  attr_reader :channel_name
  attr_accessor :stateonly
end

# This class represents an irc user.
class User < Store
  # Creates a new user with no global access
  # and and empty hosts array.
  #
  # @param [Bool] Marks whether or not this user is stateonly
  # @return [User] A new user object.
  def initialize(stateonly = true)
    @hosts = []
    @servers = {}
    @global_access = Access.new
    @stateonly = stateonly
  end
  
  # Adds a host to the collection.
  #
  # @param [String] The host to add.
  # @return [nil] Nil
  def add_host(host)
    if host.class == String
      host = Regexp.new(host)
    end
    unless @hosts.include?(host)
      @hosts << host
    end
  end

  # Removes a host from the collection.
  #
  # @param [String] The host to remove.
  # @return [nil] Nil
  def remove_host(host)
    @hosts.delete(host)
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
  # @param [Bool] If this is a state only serveruser.
  # @param [Fixnum] The power of this user.
  # @param [Array<Fixnum>] The flags for this user.
  # @return [nil] Nil
  def add_server(server_key, stateonly = true, power = 0, *flags)
    access = nil
    if power != 0 || flags.length != 0
      access = Access.new(power, *flags)
    end
    @servers[server_key] = ServerUser.new(server_key, stateonly, access)
  end

  # Removes a server.
  #
  # @param [Symbol] The server key to remove.
  # @return [nil] Nil
  def remove_server(server_key)
    @servers.delete(server_key)
  end

  # Gets a ServerUser object from the user.
  #
  # @param [Symbol] The key of the server to look up.
  # @return [ServerUser] The server user object.
  def [](key)
    return @servers[key]
  end

  # Stores persistent data on the user object.
  #
  # @param [Symbol, String] The key to this object.
  # @param [Object] Some object to store.
  # @return [nil] Nil
  def store(key, value)
    obj = for_context(self) { |c| c.store(key, value); c }
    return if obj != self 
    super(key, value)
  end

  # Fetches persistent data on the user object.
  #
  # @param [Symbol, String] The key to this object.
  # @return [Object] The object that was previously stored.
  def fetch(key)
    obj = for_context(self) { |c| c }
    if obj != self
      return obj.fetch(key)
    end
    return super(key)
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

  # Uses the current context object to perform some
  # action and returns the actions result, otherwise
  # it returns an optional return value.
  #
  # @param [Object] An object to return if a context could not be found.
  # @param [Bool] Goes as deep as channel context
  # @return [Object] Some return value passed from within the block or the ret param.
  def for_context(ret = nil, channel_depth = true, &blk)
    obj = self
    if @context_server != nil
      obj = self[@context_server]

      if @context_channel != nil && channel_depth
        obj = obj[@context_channel]
      end
    end

    if obj == self
      return ret
    else
      return yield obj
    end
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

  # Wipes the state of all channels and servers.
  #
  # @return [nil] Nil
  def wipe_all_state
    new_servers = {}
    @servers.each do |server_key, server|
      unless server.stateonly
        server.wipe_state
        new_servers[server_key] = server
      end
    end
    @servers = new_servers
  end

  # Returns the number of hosts.
  #
  # @return [Fixnum] The number of hosts.
  def hosts_count
    return @hosts.length
  end

  #Proxy attributes for ServerUser contexts

  # Checks to see if the contextual object is online.
  #
  # @return [Bool] Online or not?
  def online?
    return for_context(false) { |c| c.online? }
  end

  # Gets the current channel names for the ServerUser context.
  #
  # @return [Array<String>] Channel names.
  def channels
    return for_context(nil, false) { |c| c.channels }
  end

  # Gets the fullhost for the ServerUser context.
  #
  # @return [String] The fullhost.
  def fullhost
    return for_context(nil, false) { |c| c.fullhost }
  end

  # Gets the host for the ServerUser context.
  #
  # @return [String] The host.
  def host
    return for_context(nil, false) { |c| c.host }
  end

  # Gets the nick for the ServerUser context.
  #
  # @return [String] The nick.
  def nick
    return for_context(nil, false) { |c| c.nick }
  end

  # Gets the realname for the ServerUser context.
  #
  # @return [String] The realname.
  def realname
    return for_context(nil, false) { |c| c.realname }
  end

  #Proxy attributes for ChannelUser contexts

  # Checks the ChannelUser context for a specific mode.
  #
  # @param [String] Mode to check for.
  # @return [Bool] True or false.
  def has_mode?(arg)
    return for_context(false) { |c| c.has_mode?(arg) }
  end

  # Gets the channel name from the ChannelUser context.
  #
  # @return [String] The channel name.
  def channel_name
    return for_context(false) { |c| c.channel_name }    
  end

  # Iterates through each mode for the ChannelUser context.
  #
  # @param [Block] The block to call for each mode.
  # @return [Object] The return of the block passed.
  def each_mode(&blk)
    return for_context(false) { |c| c.each_mode(&blk) }
  end

  attr_reader :global_access
  attr_accessor :stateonly
end

