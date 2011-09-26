require_relative '../src/irc_protocol'

describe "IrcProtocol" do
  before :each do
    @i = IrcProtocol.new('irc.proto')
  end

  it "should read in a file on instantiation" do
    @i.event_count.should be > 0
  end

  it "should contain at least one event after instantation" do
    @i.has_event?(:notice).should be_true
  end

  it "should be able to be cleared" do
    @i.clear
    @i.event_count.should be_zero
    @i.has_event?(:notice).should be_false
  end

  it "should parse a language into an event" do
    event = @i.send(:parse_event, 'PRIVMSG 1 :')
    event.should include(:lex)
    event[:lex].length.should eq(2)
    event[:lex][0].should include(:rule => :single, :args => 1)
    event[:lex][1].should include(:rule => :remaining)
    event = @i.send(:parse_event, '672 3 :')
    event[:lex][0].should include(:rule => :single, :args => 3)
    event[:lex][1].should include(:rule => :remaining)
    @i.has_event?(:i672).should be_true
    @i.has_event?(:privmsg).should be_true
  end

  it "should parse optional chains" do
    @i.send(:parse_event, 'LIST [1 [1]]')
  end

  it "should die on badly formatted grammars" do
    expect {
      @i.send(:parse_event, ':11{!~')
    }.to raise_error(IrcProtocol::ProtocolFormatError)
    expect {
      @i.send(:parse_event, 'hello !!4 zi2')
    }.to raise_error(IrcProtocol::ProtocolFormatError)
  end

  it "should die when parsing a nil or empty event" do
    expect { @i.send(:parse_event, '') }.to raise_error(ArgumentError)
    expect { @i.send(:parse_event, nil) }.to raise_error(ArgumentError)
  end
end

