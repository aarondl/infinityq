require 'yaml'

class Bot
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
      raise ConfigError.new('Must have servers configured.')
    end

    if Config[:nick].nil? || Config[:altnick].nil?
      raise ConfigError.new('Must have nick and altnick configured.')
    end

    for k, v in Bot::Config[:servers]
      if v[:address].nil?
        raise ConfigError.new('Servers must have addresses configured')
      end
    end
  end

  class ConfigError < RuntimeError
    attr_reader :message
    def initialize(msg)
      @message = msg
    end
  end
end
