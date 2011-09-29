require_relative '../src/function_registrar'

describe "FunctionRegistrar" do
  before :each do
    @test = false
    @i = IrcProtoEvent.new('irc.proto')
    @f = FunctionRegistrar.new(@i, '!')
    @token = @f.register(:private, lambda { |args| @test = args }, 'hi')
  end

  it "should instantiate with an IrcProtoEvent" do
    @f.should_not be_nil
  end

  it "should register functions" do
    @token.should_not be_nil
  end

  it "should raise an error if people try to register bad functions or events" do
    expect {
      @f.register(:lol, nil, nil)
    }.to raise_error(ArgumentError)
  end

  it "should register a single event to handle multiple functions" do
    @i.event_count(:privmsg).should eq(1)
    @f.register(:private, lambda {}, 'hello')
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
    @f.register(:notice, lambda { |args| @test = args}, 'yo')
    @i.parse_proto(':fish@fish.com PRIVMSG Aaron :!hi there')
    @test.should_not be_nil
    @test.should include(:msg => 'there')
    @i.parse_proto(':fish@fish.com NOTICE Aaron :!yo budday!')
    @test.should_not be_nil
    @test.should include(:msg => 'budday!')
  end

end
