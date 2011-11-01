# Core events are events that are required
# to make the bot run. They hook in to events
# in the same way that extensions do.
class CoreEvents
  # Creates a new CoreEvents object and binds to
  # the instance of IrcProtoEvent passed in.
  #
  # @param [IrcServer] The irc server to talk back to.
  # @param [Symbol] The server key
  # @param [IrcProtoEvent] IrcProtoEvent instance.
  # @param [UserDb] The user database.
  # @param [ChannelDb] The channel database.
  # @param [BotState] Botstate instance.
  # @param [String] Nickname for connecting.
  # @param [String] Altnickname for connecting.
  # @param [String] E-mail address for connecting.
  # @param [String] Realname for connecting.
  # @return [CoreEvents] A core events object.
  def initialize(server, server_key, irc_proto, udb, cdb, botstate, nick, altnick, email, name)
    @server = server
    @server_key = server_key
    @irc_proto = irc_proto
    @udb = udb
    @cdb = cdb
    @botstate = botstate
    @pings = 0
    @nickinuse = 0

    @nick = nick
    @altnick = altnick
    @email = email
    @realname = name

    irc_proto.register :ping, method(:ping)
    irc_proto.register :connect, method(:connect)
    irc_proto.register :e311, method(:whois_repl)
    irc_proto.register :e401, method(:no_such_nick)
    irc_proto.register :e433, method(:nick_in_use)
  end

  # The core event handler for connect.
  # Responds with Nick & User messages.
  #
  # @param [Hash] Arguments from CONNECT message.
  # @return [nil] Nil
  def connect(args)
    email = @email.split('@')
    @server.write(
      @irc_proto.helper.nick(@nick),
      @irc_proto.helper.user(email[0], '0', '*', @realname)
    )
  end

  # The core event handler for ping.
  # Responds with PONG :id
  #
  # @param [Hash] Arguments from PING message.
  # @return [nil] Nil
  def ping(args)
    @server.write('PONG :' + args[:id])
    @pings += 1
  end

  # The core event handler for whois reply.
  #
  # @param [Hash] Arguments from the 311 message.
  # @return [nil] Nil
  def whois_repl(args)
    fullhost = args[:nick] + '!' + args[:user] + '@' + args[:host]
    user = @udb[fullhost]
    if user == nil
      user = User.new()
      user.add_host(fullhost)
      @udb.add(user)
    end

    user.add_server(@server_key) if user[@server_key].nil?
    user[@server_key].set_state(fullhost, args[:realname])
  end

  # The core event handler for no such nick.
  #
  # @param [Hash] Arguments from the 401 message.
  # @return [nil] Nil
  def no_such_nick(args)
    
  end
  
  # Responds to nick in use requests by sending altnick
  # followed by mangled nicknames.
  #
  # @param [Hash] The arguments from the 433 message.
  # @return [nil] Nil
  def nick_in_use(args)
    if @nickinuse == 0
      @botstate.nick = @altnick
    else
      @botstate.nick = @nick + ('_'*@nickinuse)
    end
    @server.write(@irc_proto.helper.nick(@botstate.nick))
    @nickinuse += 1
  end

  attr_reader :pings
  attr_accessor :server_key
end

