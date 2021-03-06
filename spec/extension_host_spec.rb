require_relative '../src/extension_host'
require_relative '../src/function_registrar'

describe "ExtensionHost" do
  before :each do
    @path = __FILE__.gsub(/spec\/[a-z0-9_]+\.rb/i, 'extensions')

    @fn_registrar = double('FunctionRegistrar')
    @fn_registrar.stub(:register)
    @fn_registrar.stub(:unregister)
    @irc_proto = double('IrcProtoEvent')
    @irc_proto.stub(:register)
    @irc_proto.stub(:unregister)

    @extconfig = {'Test1' => {test: :load}}
    @extdb = double('Store')

    @udb = double('UserDb')
    @cdb = double('ChanDb')

    @botstate = double('BotState')

    @e = ExtensionHost.new(@path, @extconfig, @extdb, 1, @irc_proto, @fn_registrar, @botstate, @udb, @cdb)
    @e.load_extensions 'Test1', 'Test 2'
  end

  it "should add to the load path" do
    $:[$:.length-1].should eq(@e.path)
  end

  it "should instantiate extensions with a host of helpful objects" do
    class Test1
      attr_reader :irc_proto, :server, :fn_registrar, :cfg, :db, :botstate, :udb, :cdb
    end
    obj = @e.extension(:Test1)
    obj.server.should_not be_nil
    obj.irc_proto.should_not be_nil
    obj.fn_registrar.should_not be_nil
    obj.cfg.should_not be_nil
    obj.db.should_not be_nil
    obj.udb.should_not be_nil
    obj.cdb.should_not be_nil
    obj.botstate.should_not be_nil
  end

  it "should clean the load path" do
    @e.clean_load_path
    $:.should_not include(@path)
  end

  it "should load a list of extensions" do
    Object.const_defined?(:Test1).should be_true
    Object.const_defined?(:Test_2).should be_true
  end

  it "should be able to retrieve the extension objects" do
    @e.extension(:Test1).should be_a(Test1)
  end

  it "should invoke ext_load" do
    $nasty_test.should eq(:load)
  end

  it "should invoke ext_unload" do
    @e.unload_extensions :Test1
    $nasty_test.should eq(:unload)
  end

  it "should unload extensions" do
    @e.unload_extensions 'Test 2' 
    Object.const_defined?(:Test_2).should be_false
    @e.extensions.should_not include(:Test_2)
  end

  it "should maintain a list of extensions" do
    @e.extensions.should include(:Test1, :Test_2)
  end
end

