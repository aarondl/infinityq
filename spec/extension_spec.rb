require_relative '../src/extension'
require_relative '../src/irc_proto_event'
require_relative '../src/function_registrar'
require_relative '../src/irc_server'

describe "Extension" do
  before :each do
    if Object.const_defined?(:BotExtension)
      Object.send(:remove_const, :BotExtension)
    end
    class BotExtension < Extension
      attr_accessor :test
    end
    @irc_proto = IrcProtoEvent.new('irc.proto')
    @fn_registrar = FunctionRegistrar.new(@irc_proto, '!')
    @server = IrcServer.new('irc.gamesurge.net')
    @server.connect
    @ext = BotExtension.new(@server, @irc_proto, @fn_registrar)
  end

  it "should be inherited by aspiring modules" do
    @ext.should be_kind_of(Extension)
  end

  it "should expect to be initialized by ext_load" do
    class BotExtension
      def ext_load; @test = true; end
    end
    @ext = BotExtension.new(nil, nil, nil)
    @ext.test.should be_true
  end

  it "should be able to register and unregister its events" do
    class BotExtension
      def ext_load; event :privmsg, :privmsg; end
      def privmsg(args); @test = args[:user]; end
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
        function :private, :help, /^help/
        function :notice, :help, 'help'
        function :public, :help, 'help'
      end
      def help(args); @test = args[:msg]; end
    end
    @ext.ext_load
    @ext.test.should be_nil
    @irc_proto.parse_proto('PRIVMSG Aaron :!help me!')
    @ext.test.should eq('me!')
  end

  it "should be able to send messages to the server" do
    class BotExtension
      def gogo; raw irc.privmsg_helper('Aaron', 'Pewpewpew'); end
    end
    @ext.gogo
  end

end

