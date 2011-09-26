require_relative '../src/irc_protocol_file_factory'

describe "IrcProtocolFileFactory" do
  it "should return a different class based on the environment settings" do
    if ENV['RBB_ENV'] == 'TEST'
      IrcProtocolFileFactory::get_file('irc.proto').should be_a(IrcMockProtocolFile)
    else
      IrcProtocolFileFactory::get_file('irc.proto').should be_a(File)
    end
  end
end

