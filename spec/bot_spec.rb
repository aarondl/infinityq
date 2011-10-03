require_relative '../src/bot'
require_relative '../src/bot_instance'

describe "Bot" do
  it "should create a server object for each server in the config" do
    Bot::read_config
    Bot::start
    Bot::Config[:servers].each_key do |k|
      Bot::instance(k).should be_kind_of(BotInstance)
    end
  end

  it "should iterate through all the servers" do
    Bot::read_config
    Bot::start
    Bot::each do |i|
      i.should be_kind_of(BotInstance)
      Bot::Config[:servers].should include(i.key)
    end
  end
end

