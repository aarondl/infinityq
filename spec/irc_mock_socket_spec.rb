require_relative '../src/irc_mock_socket'

describe "IrcMockSocket" do
  before :each do
    @i = IrcMockSocket.new('irc.gamesurge.net', 6667)
  end

  it "should respond with ping after recieving nick/user in order" do
    @i.write("NICK something\r\n").should eq(16)
    @i.write("USER a 0 * :fraud\r\n").should eq(19)
    @i.recv(nil).should match(/PING :[0-9]+/)
    @i.recv(nil).should match(/[0-9]+\r\n/)
  end

  it "should be able to be closed" do
    @i.close
  end

  it "should provide info about the connection" do
    @i.remote_address.ip_address.should match(/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/)
    @i.remote_address.ip_port.should eq(6667)
  end
end

