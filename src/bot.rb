require 'yaml'
require_relative 'exceptions'

# Ruby IRC Bot main class
class Bot
  # Used to define the bot's current state
  class State
    # Connected state
    Connected = 1
  end
  # The static config path to the config file
  ConfigPath = 'config.yml'
  # The config hash that will contain the config details
  Config = {}

  # Reads a config from a file.
  #
  # @param [Path] The path to the config file, falls back to Bot::ConfigPath
  def self.read_config(path = nil)
    hash = YAML::load_file(path || ConfigPath)
    Config.clear
    hash.each do |k, v|
      Config[k] = v
    end
  end

  # Starts the bot
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

  # Gets the state of the bot
  #
  # @return [Bot::State] The current bot state
  def self.state?
    return Bot::State::Connected
  end

end

