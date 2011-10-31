require_relative '../src/irc_proto_event'
require_relative '../src/function_registrar'
require_relative '../src/channel/channel_db'
require_relative '../src/user/user_db'

describe "FunctionRegistrar" do
  before :each do
    @test = false
    @udb = UserDb.new()
    @i = IrcProtoEvent.new('irc.proto', @udb, ChannelDb.new(), :gamesurge)
    @f = FunctionRegistrar.new(@i, '!')
    @token = @f.register(:privmsg, :private, -> args { @test = args }, 'hi')
  end

  it "should instantiate with an IrcProtoEvent" do
    @f.should_not be_nil
  end

  it "should register functions" do
    @token.should_not be_nil
  end

  it "should raise an error if people try to register bad functions or events" do
    expect {
      @f.register(:lol, :both, nil, nil)
    }.to raise_error(ArgumentError)
    expect {
      @f.register(:both, :lol, nil, nil)
    }.to raise_error(ArgumentError)
  end

  it "should register a single event to handle multiple functions" do
    @i.event_count(:privmsg).should eq(1)
    @f.register(:privmsg, :private, -> {}, 'hello')
    @i.event_count(:privmsg).should eq(1)
  end

  it "should unregister events" do
    @f.unregister(@token)
  end

  it "should unregister all events when collapsed" do
    @i.event_count(:privmsg).should eq(1)
    @f.collapse
    @i.event_count(:privmsg).should eq(0)
  end

  it "should respond to privmsg to a user" do
    @f.register(:notice, :private, -> args { @test = args }, 'yo')
    @i.parse_proto(':fish!fish@fish.com PRIVMSG Aaron :hi there')
    @test.should_not be_nil
    @test.should include(msg: 'there')
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :yo budday!')
    @test.should_not be_nil
    @test.should include(msg: 'budday!')
  end

  it "should respond to pubmsg to a user" do
    @f.register(:notice, :public, -> args { @test = args }, 'yo')
    @i.parse_proto(':fish!fish@fish.com NOTICE #hiworld :!yo budday!')
    @test.should_not be_nil
    @test.should include(msg: 'budday!')
  end

  it "should allow events to be registered on both msgtypes" do
    @f.register(:both, :private, -> args { @test = args }, 'k')
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :k budday!')
    @test.should include(msg: 'budday!')
    @i.parse_proto(':fish!fish@fish.com PRIVMSG Aaron :k sir')
    @test.should include(msg: 'sir')
  end

  it "should allow functions to be registered on both public and private" do
    @f.register(:both, :both, -> args { @test = args }, 'k')
    @i.parse_proto(':fish!fish@fish.com PRIVMSG Aaron :k thing')
    @test.should include(msg: 'thing')
    @i.parse_proto(':fish!fish@fish.com NOTICE #somechan :!k guy')
    @test.should include(msg: 'guy')
  end

  it "should allow constraints to be set on access" do
    fish = User.new()
    fish.add_host(/fish\.com$/)
    fish.add_server(:gamesurge)
    access = fish[:gamesurge].access
    access.power = 5
    access.add('c')
    @udb.add(fish)

    @f.register(:notice, :private, -> args { @test = true }, 'hi', access: 10, any_of: 'ab')
    @f.register(:notice, :private, -> args { @test = true }, 'there', all_of: 'abc')
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :hi there')
    @test.should be_false
    access.power = 10
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :hi there')
    @test.should be_false
    access.add('a')
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :hi there')
    @test.should be_true
    
    @test = false
    access.power = 5
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :hi there')
    @test.should be_false

    @test = false
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :there there')
    @test.should be_false
    access.add('b')
    @i.parse_proto(':fish!fish@fish.com NOTICE Aaron :there there')
    @test.should be_true
  end
end

