require_relative '../src/extension'
require_relative '../src/irc_proto_event'
require_relative '../src/function_registrar'
require_relative '../src/irc_server'
require_relative '../src/channel/channel_db'
require_relative '../src/user/user_db'
require_relative '../src/log'

describe "Extension" do
  before :each do
    if Object.const_defined?(:BotExtension)
      Object.send(:remove_const, :BotExtension)
    end
    class BotExtension < Extension
      attr_accessor :test
    end
    @irc_proto = IrcProtoEvent.new('irc.proto', UserDb.new(), ChannelDb.new(), :gamesurge)
    @fn_registrar = FunctionRegistrar.new(@irc_proto, '!')
    @server = IrcServer.new('localhost')
    @server.connect
    @udb = double('UserDb')
    @cdb = double('ChanDb')
    @botstate = double('BotState')
    @extdb = double('Store')
    @ext = BotExtension.new({}, @extdb, @server, @irc_proto, @fn_registrar, @botstate, @udb, @cdb)
  end

  it "should be inherited by aspiring modules" do
    @ext.should be_kind_of(Extension)
  end

  it "should expect to be initialized by ext_load" do
    class BotExtension
      def ext_load; @test = true; end
    end
    @ext = BotExtension.new(nil, nil, nil, nil, nil, nil, nil, nil)
    @ext.ext_load
    @ext.test.should be_true
  end

  it "should have a place to store its things" do
    class BotExtension
      attr_reader :db
    end
    s = Store.new()
    s[:test] = :test
    @ext = BotExtension.new(nil, s, nil, nil, nil, nil, nil, nil)
    @ext.db[:test].should eq(:test)
  end

  it "should be able to register and unregister its events" do
    class BotExtension
      def ext_load; event :privmsg, :privmsg; end
      def privmsg(args); @test = args[:target]; end
    end
    @irc_proto.parse_proto('PRIVMSG Aaron :Hello')
    @ext.test.should be_nil
    @ext.ext_load
    @irc_proto.parse_proto('PRIVMSG Aaron :Hello')
    @ext.test.should eq('Aaron')
    @ext.unload
    @irc_proto.parse_proto('PRIVMSG Fish :Hello')
    @ext.test.should_not eq('Fish')
  end

  it "should be able to register functions" do
    class BotExtension
      def ext_load
        function :privmsg, :private, :help, /^help/
        function :notice, :private, :help, 'help'
        function :privmsg, :public, :help, 'help'
      end
      def help(args); @test = args[:msg]; end
    end
    @ext.ext_load
    @ext.test.should be_nil
    @irc_proto.parse_proto('PRIVMSG Aaron :help me!')
    @ext.test.should eq('me!')
  end

  it "should be able to send messages to the server" do
    class BotExtension
      def gogo; raw irc.privmsg('Aaron', 'Pewpewpew'); end
    end
    @ext.gogo
  end

  it "should be able to find a user by host or nick" do
    @udb.should_receive(:find).with('Aaron!aaron@bitforge.ca')
    @udb.should_receive(:find_by_nick).with(:gamesurge, 'aaron')
    class BotExtension
      def f; find_user 'aaron'; find_user 'Aaron!aaron@bitforge.ca' end
    end
    @ext.f
  end

  it "should be able to find a channel by name" do
    @cdb.should_receive(:find).with(:gamesurge, '#C++')
    class BotExtension
      def f; find_chan '#C++'; end
    end
    @ext.f
  end

  it "should have a mechanism to whois users without brutal syntax" do
    @udb.should_receive(:[]).with('Aaron!~aaron@bitforge.ca') { User.new() }
    class BotExtension
      def whois(nick, method); fetch_user nick, method; end
      def who(user); @test_whois = user; end
      def who2(user); @test_whois2 = user; end
      attr_accessor :test_whois, :test_whois2
    end
    @ext.whois('Aaron', :who)
    @ext.whois('Aaron', :who2)
    @ext.test_whois.should be_nil
    @ext.test_whois2.should be_nil
    @irc_proto.parse_proto('311 iq Aaron ~aaron bitforge.ca * :Aaron L')
    @ext.test_whois.should be_a(User)
    @ext.test_whois2.should be_a(User)
  end

  it "should have a nice way of accessing various internals" do
    @extdb.should_receive(:[]=).with(:hello, :hi)
    @extdb.should_receive(:[]).with(:hello) { :hi }
    class BotExtension
      def use_db; db[:hello] = :hi; end
      def get_db; db[:hello]; end

      def use_cfg; return cfg; end
      def use_udb; return udb; end
      def use_cdb; return cdb; end
      def use_bot; return bot; end
      def use_serv_sym; return svr; end
    end
    @ext.use_db
    @ext.get_db.should eq(:hi)
    @ext.use_cfg.should_not be_nil
    @ext.use_udb.should_not be_nil
    @ext.use_cdb.should_not be_nil
    @ext.use_bot.should_not be_nil
    @ext.use_serv_sym.should eq(@irc_proto.server_key)
  end
end

