require_relative '../src/irc_mock_protocol_file.rb'

describe "IrcMockProtocolFile" do
  it "should fetch lines" do
    i = IrcMockProtocolFile.new()
    lines = i.readlines
    lines.count.should_not be_zero
    lines.each do |line|
      line.should_not be_nil
    end
  end

  it "should be able to be closed" do
    expect { IrcMockProtocolFile.new().close }.to_not raise_error
  end
end
