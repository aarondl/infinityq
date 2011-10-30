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
      extpath: __FILE__.gsub(/spec\/[a-z0-9_]+\.rb/i, 'extensions'),
      extprefix: '.', key: :gamesurge
    }

    @b = BotInstance.new(config, UserDb.new(), ChannelDb.new())
  end

  it "should take a configuration chunk to create it" do
    @b.server.should be_kind_of(IrcServer)
    @b.proto.should be_kind_of(IrcProtoEvent)
    @b.core_events.should be_kind_of(CoreEvents)
    @b.exthost.should be_kind_of(ExtensionHost)
    @b.fn_registrar.should be_kind_of(FunctionRegistrar)
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

