require 'yaml'
require_relative '../src/bot'

describe "Bot" do
  before :each do
    init_config
  end

  def init_config
    config = YAML::load(
      ":nick: infinityq\n" +
      ":altnick: infinityqq\n" +
      ":name: Infinity Ruby Bot\n" +
      ":email: inf_bot@gmail.com\n" +
      ":proto: irc.proto\n" +
      ":extpath: .\n" +
      ":extprefix: .\n" +
      ":extensions:\n" +
      "  -Test1\n" +
      ":servers:\n" +
      "  :gamesurge:\n" +
      "    :address: irc.gamesurge.net\n" +
      "    :port: 6667\n" +
      "    :nick: infinity_\n" +
      "    :altnick: infinity__\n"
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

  it "should die if a config file cannot be found" do
    expect {
      Bot::read_config 'miscellaneousrandompath.yml'
    }.to raise_error(Errno::ENOENT)
  end

  it "should read a config file" do
    c = YAML::load_file(Bot::ConfigPath)
    Bot::read_config
    Bot::Config[:nick].should eq(c[:nick])
  end

  it "should copy global values into the server-specific configs" do
    c = YAML::load_file(Bot::ConfigPath)
    Bot::read_config
    Bot::Config[:servers][:bitforge][:extensions].should eq(Bot::Config[:extensions])
  end

  it "should die if no servers exist" do
    Bot::Config.hash_temp_del(:servers) do
      expect { Bot::validate_config }.to raise_error(
        Bot::ConfigError,
        'Must have servers configured.'
      )
    end
  end
  
  it "should die if servers have no addresses" do
    Bot::Config[:servers][:gamesurge].hash_temp_del(:address) do
      expect { Bot::validate_config }.to raise_error(
        Bot::ConfigError,
        'Servers must have addresses configured.'
      )
    end
  end
  
  it "should die if no bot details are configured" do
    Bot::Config.hash_temp_del([:nick, :altnick, :name, :email]) do
      expect { Bot::validate_config }.to raise_error(
        Bot::ConfigError,
        'Must have nick, altnick, name, and email configured.'
      )
    end
  end

  it "should die if no proto file is configured" do
    Bot::Config.hash_temp_del(:proto) do
      expect { Bot::validate_config }.to raise_error(
        Bot::ConfigError,
        'Must have a proto file configured.'
      )
    end
  end

  it "should die if no extension path is configured and extensions are configured" do
    Bot::Config.hash_temp_del(:extpath) do
      expect { Bot::validate_config }.to raise_error(
        Bot::ConfigError,
        'Extensions must have a prefix and path.'
      )
    end
  end

  it "should die if no extension prefix is configured and extensions are configured" do
    Bot::Config.hash_temp_del(:extprefix) do
      expect { Bot::validate_config }.to raise_error(
        Bot::ConfigError,
        'Extensions must have a prefix and path.'
      )
    end
  end
end

