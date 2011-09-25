require_relative '../src/server.rb'

describe "Server" do
  before :each do
    @s = Server.new('irc.gamesurge.net')
    @s.state?.should eq(Server::State::Fresh)
    @s.connect
  end

  it "should connect to an address" do
    @s.state?.should eq(Server::State::Connected)
  end

  it "should provide details about the connection" do
    @s.address.should eq('irc.gamesurge.net')
    @s.port.should eq(6667)
    s = Server.new('irc.nuclearfallout.net', 5557)
    s.address.should eq('irc.nuclearfallout.net')
    s.port.should eq(5557)
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

  it "should split messages on newlines from reads" do
    @s.write('NICK fraud', 'USER a 0 * :fraud')
    @s.read.should_not be_nil
    @s.read.should_not match(/\r\n$/)
  end

end
