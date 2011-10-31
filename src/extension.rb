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
  def initialize(cfg, extdb, server, irc_proto, fn_registrar, udb, cdb)
    @cfg = cfg
    @db = extdb
    @irc_proto = irc_proto
    @fn_registrar = fn_registrar
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
  # @param [Symbol] The type of message (:public/:private/:notice)
  # @param [Symbol] The callback method.
  # @param [String, RegExp] A matcher that must pass for the function to fire.
  # @return [nil] Nil
  def function(msgtype, method, matchspec)
    @funcs.push @fn_registrar.register(msgtype, self.method(method), matchspec)
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
end

