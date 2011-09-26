require_relative '../src/irc_server'

describe "IrcServer" do
  before :each do
    @s = IrcServer.new('irc.gamesurge.net')
    @s.state?.should eq(IrcServer::State::Fresh)
    @s.connect
  end

  after :each do
    @s.disconnect
  end

  it "should connect to an address" do
    @s.state?.should eq(IrcServer::State::Connected)
  end

  it "should provide details about the connection" do
    @s.address?.should eq('irc.gamesurge.net')
    @s.port?.should eq(6667)
    ip_addresses =
      ENV['RBB_ENV'] == 'TEST' ?
      ['64.31.0.226'] :
      `nslookup irc.gamesurge.net`.scan(/Address: (.*[0-9]{1,3})/).flatten
    ip_addresses.should include(@s.ip?)
    @s.hostname?.should_not be_nil
    s = IrcServer.new('irc.nuclearfallout.net', 5557)
    s.address?.should eq('irc.nuclearfallout.net')
  end

  it "should read from the socket" do
    @s.write('NICK fraud')
    @s.write('USER a 0 * :fraud')
    found = false
    5.times do
      found = @s.read != nil
      break if found
    end
    found.should be_true
  end

  it "should read efficiently from the socket" do
    @s.write('NICK fraud')
    @s.write('USER a 0 * :fraud')
    @s.readlines.should_not be_nil
  end

  it "should split messages on newlines from reads" do
    @s.write('NICK fraud', 'USER a 0 * :fraud')
    @s.read.should_not be_nil
    @s.read.should_not match(/\r\n$/)
  end

  it "should be able to disconnect" do
    @s.disconnect
    @s.state?.should eq(IrcServer::State::Disconnected)
  end

end

