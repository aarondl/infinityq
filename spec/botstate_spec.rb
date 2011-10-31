require_relative '../src/botstate'

describe "BotState" do
  before :each do
    @b = BotState.new()
  end

  it "should keep the current fullhost and friends" do
    host = 'infinityq!~dev@localhost'
    @b.fullhost = host
    @b.fullhost.should eq(host)
    @b.nick.should eq('infinityq')
    @b.user.should eq('~dev')
    @b.host.should eq('localhost')
  end
end

