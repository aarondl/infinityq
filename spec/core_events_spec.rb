require_relative '../src/irc_proto_event'
require_relative '../src/irc_server'
require_relative '../src/core_events'

describe "CoreEvents" do
  before :each do
    @irc = IrcProtoEvent.new('irc.proto')
    @server = IrcServer.new('localhost')
    @server.connect
    @c = CoreEvents.new(@server, @irc)
  end

  it "should attach to an IrcProto instance's ping event" do
    @irc.event_count(:ping).should eq(1)
  end

  it "should respond to ping" do
    p = @c.pings
    @irc.parse_proto('PING :29910919191')
    @c.pings.should be > p
  end
end

