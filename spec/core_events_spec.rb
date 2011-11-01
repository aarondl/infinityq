require_relative '../src/irc_proto_event'
require_relative '../src/irc_server'
require_relative '../src/core_events'
require_relative '../src/botstate'
require_relative '../src/channel/channel_db'
require_relative '../src/user/user_db'
require_relative '../src/log'

describe "CoreEvents" do
  before :each do
    @udb = UserDb.new()
    @cdb = ChannelDb.new()
    @irc = IrcProtoEvent.new('irc.proto', @udb, @cdb, :gamesurge)
    @botstate = BotState.new()
    @server = IrcServer.new('localhost')
    @server.connect
    @c = get_core_evs(@server)
  end

  def get_core_evs(server)
    return CoreEvents.new(server, @irc.server_key, @irc, @udb, @cdb, @botstate, 'irc', 'ircb', 'a@a.com', 'lol')
  end

  it "should attach to an IrcProto instance's ping event" do
    @irc.event_count(:ping).should eq(1)
  end

  it "should attach to an IrcProto instance's connect pseudo event" do
    @irc.event_count(:connect).should eq(1)
  end

  it "should attach to an IrcProto instance's 401 and 311 handlers" do
    @irc.event_count(:e401).should eq(1)
    @irc.event_count(:e311).should eq(1)
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

  it "should enter users into the userdb if whois'd" do
    @udb['Aaron!~aaron@bitforge.ca'].should be_nil
    @irc.parse_proto('311 iq Aaron ~aaron bitforge.ca * :Aaron L')
    user = @udb['Aaron!~aaron@bitforge.ca']
    user.should_not be_nil
    user[@irc.server_key].online?.should be_true
  end

  it "should amend users in the userdb if whois'd" do
    fish = User.new()
    fish.add_host(/$fish!/)
    fish.add_server(@c.server_key, false)
    fish[@c.server_key].online?.should be_false
    @udb.add(fish)
    @irc.parse_proto('311 iq fish ~fish fish.com * :Fish Goes Meow')
    user = @udb['fish!~fish@fish.com']
    user.should_not be_nil
    user[@c.server_key].online?.should be_true
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

