# Core events are events that are required
# to make the bot run. They hook in to events
# in the same way that extensions do.
class CoreEvents
  # Creates a new CoreEvents object and binds to
  # the instance of IrcProtoEvent passed in.
  #
  # @param [IrcServer] The irc server to talk back to.
  # @param [IrcProtoEvent] IrcProtoEvent instance.
  # @param [String] Nickname for connecting.
  # @param [String] Altnickname for connecting.
  # @param [String] E-mail address for connecting.
  # @param [String] Realname for connecting.
  # @return [CoreEvents] A core events object.
  def initialize(server, irc_proto, nick, altnick, email, name)
    @server = server
    @irc_proto = irc_proto
    @pings = 0
    @nickinuse = 0

    @nick = nick
    @altnick = altnick
    @email = email
    @realname = name

    irc_proto.register(:ping, method(:ping))
    irc_proto.register(:connect, method(:connect))
    irc_proto.register(:e433, method(:nick_in_use))
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

  # Responds to nick in use requests by sending altnick
  # followed by mangled nicknames.
  #
  # @param [Hash] The arguments from the 433 message.
  # @return [nil] Nil
  def nick_in_use(args)
    if @nickinuse == 0
      @server.write(@irc_proto.helper.nick(@altnick))
    else
      @server.write(@irc_proto.helper.nick(@nick + ('_'*@nickinuse)))
    end
    @nickinuse += 1
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
  
  attr_reader :pings
end

