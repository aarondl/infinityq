require_relative 'irc_proto_event'

# This class is the base class for all extensions.
class Extension
  # Creates a new Extension with access to the
  # current connections IrcProtoEvent instance.
  #
  # @param [Hash] Configuration passed in from the bot config file.
  # @param [Store] The extension database.
  # @param [IrcServer] The irc server to send data to.
  # @param [IrcProtoEvent] The IrcProtoEvent for the connection.
  # @param [FunctionRegistrar] A function registrar to register functions.
  # @param [UserDb] User database.
  # @param [ChanDb] Channel database.
  # @return [Extension] A new extension.
  def initialize(cfg, extdb, server, irc_proto, fn_registrar, botstate, udb, cdb)
    @cfg = cfg
    @db = extdb
    @irc_proto = irc_proto
    @fn_registrar = fn_registrar
    @botstate = botstate
    @udb = udb
    @cdb = cdb
    @server = server
    @tokens = []
    @funcs = []
  end

  # Registers an event for this extension.
  # Ensuring that the token is kept for unregistration.
  #
  # @param [Symbol, String] The event to register.
  # @param [Symbol] The callback method.
  # @return [nil] Nil
  def event(type, method)
    @tokens.push @irc_proto.register(type, self.method(method))
    return nil
  end

  # Registers function for this extension.
  # Ensuring that the token is kept for unregistration.
  #
  # @param [Symbol] The type of message (:privmsg/:notice/:both)
  # @param [Symbol] The publicity of the message (:public/:private/:both)
  # @param [Symbol] The callback method.
  # @param [String, RegExp] A matcher that must pass for the function to fire.
  # @param [Hash] Access required (:access, :any_of, :all_of)
  # @return [nil] Nil
  def function(msgtype, publicity, method, matchspec, access_required = nil)
    @funcs.push @fn_registrar.register(msgtype, publicity, self.method(method), matchspec, access_required)
    return nil
  end

  # Unloads this extension by unregistering all it's events.
  #
  # @return [nil] Nil
  def unload
    @tokens.each do |tok|
      @irc_proto.unregister(tok)
    end
    @funcs.each do |tok|
      @fn_registrar.unregister(tok)
    end
  end

  protected
  # Whois' a user and returns the user object once CoreEvents
  # sets it after the server returns the whois query.
  #
  # @param [String] Nickname.
  # @param [Symbol] A callback method name.
  # @return [nil] Nil
  def fetch_user(nick, callback)
    if @whois_token == nil
      @whois_token = event(:e311, :whois_server_callback)
    end
    if @whois_queue == nil
      @whois_queue = {}
    end
    if @whois_queue.has_key?(nick)
      @whois_queue[nick].push(method(callback))
    else
      @whois_queue[nick] = [method(callback)]
    end
    raw irc.whois(nick)
  end

  # Handles a whois message and fetches the user object.
  # Then empties the queue for all callbacks registered to
  # wait for this callback.
  #
  # @param [Hash] The arguments from the e311 event.
  # @return [nil] Nil
  def whois_server_callback(args)
    queue = @whois_queue[args[:nick]]
    return if queue.nil?

    fullhost = args[:nick] + '!' + args[:user] + '@' + args[:host]
    user = @udb[fullhost]

    return if user.nil?
    queue.each do |c|
      c.call user
    end

    @whois_queue.delete(args[:nick])
  end

  # Writes a message to the server.
  #
  # @param [String, Array<String>] Messages to write to the server.
  # @return [nil] Nil
  def raw(msg)
    @server.write(msg)
  end

  # Retrieves the IrcProtoEvent::Helper instance to call
  # helper functions on.
  #
  # @return [IrcProtoEvent::Helper] An IrcProtoEvent::Helper instance.
  def irc
    @irc_proto.helper
  end

  # Retrieves a user from the user database.
  #
  # @param [String] Nickname or Fullhost
  # @return [User] A user object.
  def find_user(user)
    if user.include?('@')
      return @udb.find(user)
    end
    return @udb.find_by_nick(@irc_proto.server_key, user)
  end

  # Retrieves a channel from the channel database.
  #
  # @param [String] Channel name.
  # @return [Channel] The channel object.
  def find_chan(chan)
    return @cdb.find(@irc_proto.server_key, chan)
  end

  # Helper method to get the database
  #
  # @return [Store] The database object.
  def db
    return @db
  end

  # Helper method to get the configuration.
  #
  # @return [Hash] The configuration for this extension.
  def cfg
    return @cfg
  end

  # Helper method to get the user database.
  #
  # @return [UserDb] The user database object.
  def udb
    return @udb
  end

  # Helper method to get the channel database.
  #
  # @return [ChannelDb] The channel database object.
  def cdb
    return @cdb
  end

  # Helper method to get the botstate.
  #
  # @return [BotState] The botstate object.
  def bot
    return @botstate
  end

  # Helper method to get the server key.
  #
  # @return [Symbol] The server key.
  def svr
    return @irc_proto.server_key
  end
end

