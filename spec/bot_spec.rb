require_relative '../src/bot.rb'

describe "Bot" do
  it "should connect to a server" do
    Bot::read_config
    Bot::start
    Bot::state?.should eq(Bot::State::Connected)    
  end
end

