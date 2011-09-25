require_relative '../src/irc_mock_socket.rb'

describe "IrcMockSocket" do
  it "should respond with ping after recieving nick/user in order" do
    i = IrcMockSocket.new(nil, nil)
    i.read.should be_empty
    i.write("USER a 0 * :fraud\r\n")
    i.write("NICK something\r\n")
    i.read.should be_empty
    i.write("USER a 0 * :fraud\r\n")
    i.read.should match(/PING :[0-9]+\r\n/)
  end
end
