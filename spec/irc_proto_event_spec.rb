require_relative '../src/irc_proto_event'

describe "IrcProtoEvent" do
  before :each do
    @i = IrcProtoEvent.new('irc.proto')
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
    @i.event_count.should eq(1) #Raw is preserved
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
    @i.parse_proto(':fish@lol.com NOTICE Aaron :Hey man, wake up!')
    arguments.should_not be_nil
    arguments.should include(
      from: 'fish@lol.com',
      user: 'Aaron',
      msg: 'Hey man, wake up!'
    )
  end

  it "should always dispatch to raw" do
    arguments = nil
    @i.register(:raw, -> args { arguments = args })
    @i.parse_proto(':fish@lol.com PEWPEW hello there!')
    arguments.should_not be_nil
    arguments.should include(
      from: 'fish@lol.com',
      raw: 'PEWPEW hello there!'
    )
  end

  it "should throw protocol parse errors when bad protocol comes in" do
    @i.clear
    @i.register(:notice, -> {})
    expect {
      @i.parse_proto(':fish@lol.com NOTICE')
    }.to raise_error(IrcProtoEvent::ProtocolParseError)
    @i.clear
  end

  it "should have a fallback event called raw" do
    @i.has_event?(:raw).should be_true
    @i.clear true
    @i.has_event?(:raw).should be_true
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

  it "should parse csvlists" do
    event = @i.send(:parse_event, 'LIST *listname')[:rules][0]
    event.should include(rule: :csvlist, name: :listname)
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
    helper.respond_to?('notice_helper').should be_true
    helper.notice_helper('Aaron', 'Hey there man').should eq('NOTICE Aaron :Hey there man')
    helper.list_helper(['#hi', '#there']).should eq('LIST #hi,#there')
    @i.clear true
    helper.respond_to?('notice_helper').should be_false
  end

  it "should provide the names of notice and privmsg arguments" do
    @i.privmsg_args?.should include(:user, :msg)    
    @i.notice_args?.should include(:user, :msg)    
  end
end

