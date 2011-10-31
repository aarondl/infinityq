require_relative '../src/irc_proto_event'
require_relative '../src/irc_server'
require_relative '../src/core_events'
require_relative '../src/botstate'
require_relative '../src/channel/channel_db'
require_relative '../src/user/user_db'

describe "CoreEvents" do
  before :each do
    @irc = IrcProtoEvent.new('irc.proto', UserDb.new(), ChannelDb.new(), :gamesurge)
    @botstate = BotState.new()
    @server = IrcServer.new('localhost')
    @server.connect
    @c = get_core_evs(@server)
  end

  def get_core_evs(server)
    return CoreEvents.new(server, @irc, @botstate, 'irc', 'ircb', 'a@a.com', 'lol')
  end

  it "should attach to an IrcProto instance's ping event" do
    @irc.event_count(:ping).should eq(1)
  end

  it "should attach to an IrcProto instance's connect pseudo event" do
    @irc.event_count(:connect).should eq(1)
  end

  it "should respond to ping" do
    p = @c.pings
    @irc.parse_proto('PING :29910919191')
    @c.pings.should be > p
  end

  it "should respond to connect by writing nick and user" do
    @irc.fire_pseudo(:connect, {address: @server.address?, port: @server.port?})
    @server.read.should_not be_nil #Before the server receives nick & user it will
    # not respond in any way shape or form, therefore this is a definitive test.
  end

  it "should respond to 433 by sending altnick and mangled versions of nick thereafter" do
    s = double('Server').as_null_object
    c = get_core_evs(s)
    s.should_receive(:write).with('NICK ircb').ordered
    s.should_receive(:write).with('NICK irc_').ordered
    s.should_receive(:write).with('NICK irc__').ordered
    @irc.parse_proto('433 ircb :nickname in use')
    @irc.parse_proto('433 irc_ :nickname in use')
    @irc.parse_proto('433 irc__ :nickname in use')
  end
end

