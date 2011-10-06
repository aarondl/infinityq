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

    @nick = nick
    @altnick = altnick
    @email = email
    @realname = name

    irc_proto.register(:ping, method(:ping))
    irc_proto.register(:connect, method(:connect))
  end

  # The core event handler for connect.
  # Responds with Nick & User messages.
  #
  # @param [Hash] Arguments from CONNECT message.
  # @return [nil] Nil
  def connect(args)
    email = @email.split('@')
    @server.write(
      @irc_proto.helper.nick_helper(@nick),
      @irc_proto.helper.user_helper(email[0], '0', '*', @realname)
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
  
  attr_reader :pings
end

