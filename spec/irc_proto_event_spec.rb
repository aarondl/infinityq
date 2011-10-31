require_relative '../src/irc_proto_event'
require_relative '../src/channel/channel_db'
require_relative '../src/channel/channel'
require_relative '../src/user/user_db'
require_relative '../src/user/user'

describe "IrcProtoEvent" do
  before :each do
    @userdb = UserDb.new()
    @chandb = ChannelDb.new()
    @i = IrcProtoEvent.new('irc.proto', @userdb, @chandb, :gamesurge)
  end

  it "should read in a file on instantiation" do
    @i.event_count.should be > 0
  end

  it "should contain at least one event after instantation" do
    @i.has_event?(:notice).should be_true
  end

  it "should know how many callbacks are registered to an event" do    
    @i.event_count(:privmsg).should be_zero
    @i.register(:privmsg, -> {})
    @i.event_count(:privmsg).should be(1)
  end

  it "should be able to have event data cleared" do
    @i.clear true
    @i.has_event?(:notice).should be_false
  end

  it "should be able to have event callbacks only cleared" do
    @i.clear
    @i.has_event?(:notice).should be_true
  end

  it "should register and unregister events" do
    token = @i.register(:notice, -> {})
    token.should_not be_nil
    @i.unregister(token)
  end

  it "should not register bad events" do
    @i.register(:hereisabadevent, nil).should be_nil
  end

  it "should parse irc protocol and dispatch events" do
    arguments = nil
    @i.register(:notice, -> args { arguments = args })
    @i.parse_proto(':fish!~fish@lol.com NOTICE Aaron :Hey man, wake up!')
    arguments.should_not be_nil
    arguments.should include(
      target: 'Aaron',
      msg: 'Hey man, wake up!'
    )
    arguments[:from].should be_a(User)
    arguments[:from][@i.server_key].online?.should be_true
  end

  it "should always dispatch to raw" do
    arguments = nil
    @i.register(:raw, -> args { arguments = args })
    @i.parse_proto(':fish!~fish@lol.com PEWPEW hello there!')
    arguments.should_not be_nil
    arguments.should include(
      from: 'fish!~fish@lol.com',
      raw: 'PEWPEW hello there!'
    )
    @i.parse_proto('PEWPEW hi') #Test coverage
    arguments.should include(raw: 'PEWPEW hi')
  end

  it "should throw protocol parse errors when bad protocol comes in" do
    @i.clear
    @i.register(:notice, -> {})
    expect {
      @i.parse_proto(':fish!~fish@lol.com NOTICE')
    }.to raise_error(IrcProtoEvent::ProtocolParseError)
    @i.clear
  end

  it "should parse a language into an event" do
    event = @i.send(:parse_event, '672 hi there john :more')
    event = event[:rules]
    event.length.should eq(4)
    [[:single, :hi], [:single, :there],
    [:single, :john], [:remaining, :more]].each_with_index do |expect, i|
      event[i].should include(rule: expect[0], name: expect[1])
    end
    @i.has_event?(672).should be_true
    @i.has_event?('672').should be_true
  end

  it "should parse optional chains" do
    event = @i.send(:parse_event, 'LIST [first [second]]')[:rules][0]
    event.should include(rule: :optional, 
      args: [
        {rule: :single, name: :first},
        {rule: :optional, args: [
          {rule: :single, name: :second}
        ]}
      ]
    )
  end

  it "should disregard missing optional arguments" do
    arguments = nil
    @i.register(:topic, -> args { arguments = args })
    @i.parse_proto('TOPIC #channel')
    arguments.should include(:channel)
    arguments[:topic].should be_nil
    arguments[:channel].should be_a(Channel)
  end

  it "should parse csvlists" do
    event = @i.send(:parse_event, 'NAMES *listname')[:rules][0]
    event.should include(rule: :csvlist, name: :listname)
    arguments = nil
    @i.register(:kick, -> args { arguments = args })
    @i.parse_proto('KICK #hello,#there Aaron,fish :Here is a msg')
    arguments.should include(:channellist, :nicklist, :comment)
    arguments[:channellist][0].name.should eq('#hello')
    arguments[:channellist][1].name.should eq('#there')
    arguments[:nicklist].should include('Aaron', 'fish')
    arguments[:comment].should eq('Here is a msg')
  end

  it "should parse channel arguments" do
    event = @i.send(:parse_event, 'LIST *#channels')
    event[:rules][0].should include(rule: :chanlist, name: :channels)
    event = @i.send(:parse_event, 'LIST #channel')
    event[:rules][0].should include(rule: :channel, name: :channel)
  end

  it "should die on badly formatted grammars" do
    expect {
      @i.send(:parse_event, ':11{!~')
    }.to raise_error(IrcProtoEvent::ProtocolFormatError)
    expect {
      @i.send(:parse_event, 'hello !!4 zi2')
    }.to raise_error(IrcProtoEvent::ProtocolFormatError)
    expect {
      @i.send(:parse_event, 'hello :*stuff')
    }.to raise_error(IrcProtoEvent::ProtocolFormatError)
    expect {
      @i.send(:parse_event, 'hello *:stuff')
    }.to raise_error(IrcProtoEvent::ProtocolFormatError)
    expect {
      @i.send(:parse_event, 'hello :#channelremaining')
    }.to raise_error(IrcProtoEvent::ProtocolFormatError)
  end

  it "should die when parsing a nil or empty event" do
    expect { @i.send(:parse_event, '') }.to raise_error(ArgumentError)
    expect { @i.send(:parse_event, nil) }.to raise_error(ArgumentError)
  end

  it "should expose a helper class for assembling raw" do
    @i.helper.should be_a(IrcProtoEvent::Helper)
  end

  it "should create helper methods for assembling raw" do
    helper = @i.helper
    helper.respond_to?('notice').should be_true
    helper.notice('Aaron', 'Hey there man').should eq('NOTICE Aaron :Hey there man')
    helper.list(['#hi', '#there']).should eq('LIST #hi,#there')
    @i.clear true
    helper.respond_to?('notice').should be_false
  end

  it "should create pseudo-events that persist across clears" do
    evs = [:raw, :connect, :disconnect]
    evs.each do |ev| @i.has_event?(ev).should be_true; end
    @i.clear true
    evs.each do |ev| @i.has_event?(ev).should be_true; end
  end

  it "should provide the names of notice and privmsg arguments" do
    @i.privmsg_args?.should include(:target, :msg)    
    @i.notice_args?.should include(:target, :msg)    
  end

  it "should fire pseudo events" do
    arguments = nil
    @i.register(:connect, -> args {arguments = args})
    @i.fire_pseudo(:connect, {})
    arguments.should_not be_nil
    arguments.should be_empty
  end

  it "should convert :from arg into a User object" do
    arguments = nil
    @i.register(:notice, -> args {
      arguments = args
      arguments[:from].nick.should eq('fish') #Checks context
    })
    @i.parse_proto(':fish!~fish@lol.com NOTICE Aaron :Hey man, wake up!')
    arguments[:from].should be_a(User)
  end

  it "should convert channel arguments into Channel objects" do
    arguments = nil
    fish = User.new()
    fish.add_server(@i.server_key)
    fish.add_host(/fish@lol\.com/)
    fish[@i.server_key].set_state('fish!~fish@lol.com', 'Fish!', ['#c++'])
    @userdb.add(fish)
    @i.register(:notice, -> args {
      arguments = args
      arguments[:from].channel_name.should eq('#c++') #Checks context
    })
    @i.parse_proto(':fish!~fish@lol.com NOTICE #c++ :Hey man, wake up!')
    arguments[:target].should be_a(Channel)
  end
end

