require_relative '../../src/channel/channel_db'
require_relative '../../src/channel/channel'

describe "ChannelDb" do
  before :each do
    @c = ChannelDb.new()
    @c.add(Channel.new(:gamesurge, '#C++'))
    @c.add(Channel.new(:gamesurge, '#blackjack', false))
  end

  it "should keep a list of channels" do
    @c[:gamesurge, '#c++'].should_not be_nil
    @c.find(:gamesurge, '#blackjack').should_not be_nil
  end

  it "should prepare seralizization" do
    @c.prepare_for_serialization
    @c[:gamesurge, '#c++'].should be_nil
    @c[:gamesurge, '#blackjack'].should_not be_nil
  end
end

