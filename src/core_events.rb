# Core events are events that are required
# to make the bot run. They hook in to events
# in the same way that extensions do.
class CoreEvents
  # Creates a new CoreEvents object and binds to
  # the instance of IrcProtoEvent passed in.
  #
  # @param [IrcServer] The irc server to talk back to.
  # @param [IrcProtoEvent] IrcProtoEvent instance.
  # @return [CoreEvents] A core events object.
  def initialize(server, irc_proto)
    @server = server
    @irc_proto = irc_proto
    @pings = 0

    irc_proto.register(:ping, method(:ping))
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

