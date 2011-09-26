require 'yaml'
require_relative 'exceptions'

class Bot
  class State
    Connected = 1
  end
  ConfigPath = 'config.yml'
  Config = {}

  def self.read_config(path = nil)
    hash = YAML::load_file(path || ConfigPath)
    Config.clear
    hash.each do |k, v|
      Config[k] = v
    end
  end

  def self.start
    if Config[:servers].nil?
      raise ConfigError, 'Must have servers configured.'
    end

    if (Config[:nick] && Config[:altnick] &&
        Config[:name] && Config[:email]).nil?
      raise ConfigError, 'Must have nick, altnick, name, and email configured.'
    end

    for k, v in Bot::Config[:servers]
      if v[:address].nil?
        raise ConfigError, 'Servers must have addresses configured.'
      end
    end
  end

  def self.state?
    return Bot::State::Connected
  end

end

