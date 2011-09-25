require 'yaml'
require_relative '../src/bot.rb'

describe "Bot" do
  before :each do
    config = YAML::load(
      ":nick: 'rbb'\n" +
      ":altnick: 'rbb_'\n" +
      ":name: 'rbb_bot'\n" +
      ":email: 'rbb_bot@gmail.com'\n" +
      ":servers:\n" +
      "  :gamesurge:\n" +
      "    :address: 'irc.gamesurge.net'\n" +
      "    :port: 6667\n" +
      "    :nick: 'rbb'\n" +
      "    :altnick: 'rbb2'\n"
    )

    Bot::Config.clear
    config.each do |k, v|
      Bot::Config[k] = v
    end
  end

  class Hash
    def hash_temp_del(keys, &block)
      k = []
      if keys.kind_of?(Array)
        keys.each do |i| k.push delete(i) end
      else
        k = delete(keys)
      end
      yield
      if keys.kind_of?(Array)
        keys.each do |i| self[i] = k.pop end
      else
        self[keys] = k
      end
    end
  end

  it "should read a config file" do
    c = nil
    File.open(Bot::ConfigPath) do |f|
      c = YAML::load(f)
    end
    Bot::read_config
    Bot::Config[:nick].should eq(c[:nick])
  end

  it "should die if no servers exist" do
    Bot::Config.hash_temp_del(:servers) do
      expect { Bot::start }.to raise_error(Bot::ConfigError)
    end
  end

  it "should die if no nick and altnick are configured" do
    Bot::Config.hash_temp_del([:nick, :altnick]) do
      expect { Bot::start }.to raise_error(Bot::ConfigError)
    end
  end

  it "should enforce a server structure" do
    Bot::Config[:servers][:gamesurge].hash_temp_del([:address]) do
      expect { Bot::start }.to raise_error(Bot::ConfigError)
    end
  end
end
