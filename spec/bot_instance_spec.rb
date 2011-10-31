require_relative '../src/bot_instance'
require_relative '../src/channel/channel_db'
require_relative '../src/user/user_db'

describe "BotInstance" do
  before :all do
    config = {
      nick: 'infinity', altnick: 'infinityq', 
      name: 'InfinityQ', email: 'inf@inf.com',
      address: 'localhost',
      extensions: ['Test_2'], proto: 'irc.proto',
      extensioncfg: {'Test1' => {test: :load}},
      extpath: __FILE__.gsub(/spec\/[a-z0-9_]+\.rb/i, 'extensions'),
      extprefix: '.', key: :gamesurge
    }

    @b = BotInstance.new(config, UserDb.new(), ChannelDb.new(), {})
  end

  it "should take a configuration chunk to create it" do
    @b.server.should be_a(IrcServer)
    @b.proto.should be_a(IrcProtoEvent)
    @b.core_events.should be_a(CoreEvents)
    @b.exthost.should be_a(ExtensionHost)
    @b.fn_registrar.should be_a(FunctionRegistrar)
    @b.botstate.should be_a(BotState)
    @b.key.should eq(:gamesurge)
  end
  
  it "should load modules" do
    @b.exthost.extensions.should include(:Test_2)
  end

  it "should spawn a thread for networking" do
    @b.start
    @b.thread.should_not be_nil
    @b.thread.status.should eq('run')
    @b.halt
  end
end

