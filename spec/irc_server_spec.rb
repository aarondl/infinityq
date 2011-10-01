require_relative '../src/irc_server'

describe "IrcServer" do
  before :each do
    @s = IrcServer.new('localhost')
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
    @s.address?.should eq('localhost')
    @s.port?.should eq(6667)
    ip_addresses =
      ENV['INF_ENV'] == 'TEST' ?
      ['64.31.0.226'] :
      `nslookup #{@s.address?}`.scan(/Address: (.*[0-9]{1,3})/).flatten
    ip_addresses.should include(@s.ip?)
    @s.hostname?.should_not be_nil
  end

  it "should read from the socket" do
    @s.write('NICK fraud')
    @s.write('USER a 0 * :fraud')
    @s.read.should_not be_nil
  end

  it "should split messages on newlines from reads" do
    @s.write('NICK fraud', 'USER a 0 * :fraud')
    @s.read[0].should_not match(/\r\n$/)
  end

  it "should be able to disconnect" do
    @s.disconnect
    @s.state?.should eq(IrcServer::State::Disconnected)
  end

  it "should raise an error when writing or reading to a disconnected socket" do
    @s.disconnect
    expect {
      @s.write 'data'
    }.to raise_error(IOError)
    expect {
      @s.read
    }.to raise_error(IOError)
  end

end

