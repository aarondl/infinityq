require 'yaml'
require_relative '../src/bot'

describe "Bot" do
  Config = <<-EOF
    :nick: infinityq
    :altnick: infinityqq
    :name: Infinity Ruby Bot
    :email: inf_bot@gmail.com
    :proto: irc.proto
    :extpath: .
    :extprefix: .
    :extensions:
      -Test1
    :extensioncfg:
      Test1:
        :test: :load
    :servers:
      :gamesurge:
        :address: irc.gamesurge.net
        :port: 6667
        :nick: infinity_
        :altnick: infinity__
  EOF

  before :each do
    Bot::set_config(YAML::load(Config))
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
    if ENV['INF_ENV'] != 'TEST'
      expect {
        Bot::read_config 'miscellaneousrandompath.yml'
      }.to raise_error(Errno::ENOENT)
    end
  end

  it "should read a config file" do
    FileFactory::preload(Config)
    Bot::read_config
    Bot::Config[:nick].should_not be_nil 
  end

  it "should copy global values into the server-specific configs" do
    Bot::do_config_cascade
    Bot::Config[:servers][:gamesurge][:extensions].should eq(Bot::Config[:extensions])
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

