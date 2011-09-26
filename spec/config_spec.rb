require 'yaml'
require_relative '../src/bot.rb'

describe "Bot" do
  before :all do
    init_config
  end

  def init_config
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
      values = []
      keys = keys.kind_of?(Array) ? keys : [keys]
      keys.each do |k|
        value = self.delete k
        yield
        self[k] = value
      end
    end
  end

  it "should be testable with hash_temp_del" do
    Bot::Config.hash_temp_del(:servers) do
      Bot::Config[:servers].should be_nil
    end
    Bot::Config.hash_temp_del([:nick, :servers]) do
      (Bot::Config[:servers] && Bot::Config[:nick]).should be_nil
    end
    Bot::Config[:servers].should_not be_nil
    Bot::Config[:nick].should_not be_nil
  end

  it "should read a config file" do
    c = YAML::load_file(Bot::ConfigPath)
    Bot::read_config
    Bot::Config[:nick].should eq(c[:nick])
    init_config #Restore test data
  end

  it "should die if no servers exist" do
    Bot::Config.hash_temp_del(:servers) do
      expect { Bot::start }.to raise_error(Bot::ConfigError)
    end
  end
  
  it "should die if servers have no addresses" do
    Bot::Config[:servers][:gamesurge].hash_temp_del(:address) do
      expect { Bot::start }.to raise_error(Bot::ConfigError)
    end
  end
  
  it "should die if no bot details are configured" do
    Bot::Config.hash_temp_del([:nick, :altnick, :name, :email]) do
      expect { Bot::start }.to raise_error(Bot::ConfigError)
    end
  end
end

