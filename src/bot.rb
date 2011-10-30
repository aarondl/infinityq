require 'yaml'
require_relative 'log'
require_relative 'stdout_provider'
require_relative 'bot_instance'
require_relative 'exceptions'
require_relative 'channel/channel_db'
require_relative 'user/user_db'

# Ruby IRC Bot main class
class Bot
  # The static config path to the config file
  ConfigPath = 'config.yml'
  # The config hash that will contain the config details
  Config = {}

  # Reads and validates config from a file.
  #
  # @param [String] The path to the config file, falls back to Bot::ConfigPath
  # @return [nil] Nil
  def self.read_config(path = nil)
    hash = YAML::load_file(path || ConfigPath)
    Config.clear
    hash.each do |k, v|
      Config[k] = v
    end
    
    validate_config

    cascading = [:extensions, :extprefix, :extpath, :proto, :nick, :altnick, :name, :email]
    Config[:servers].each do |k, v|
      cascading.each do |attrib|
        if Config.has_key?(attrib) && v.has_key?(attrib) == false
          v[attrib] = Config[attrib]
        end
      end
    end
  end

  # Reads the user and channel database if available.
  #
  # @return [nil] Nil
  def self.read_databases
    @@userdb = UserDb.new()
    @@chandb = ChannelDb.new()
  end

  # Validates a bot configuration.
  # Throws a ConfigError with a message if something went wrong.
  #
  # @return [nil] Nil
  def self.validate_config
    if Config[:servers].nil?
      raise ConfigError, 'Must have servers configured.'
    end

    if Config[:proto].nil?
      raise ConfigError, 'Must have a proto file configured.'
    end

    if Config[:extensions] != nil && (Config[:extprefix].nil? || Config[:extpath].nil?)
      raise ConfigError, 'Extensions must have a prefix and path.'
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

  # Starts the bot
  #
  # @return [nil] Nil
  def self.start
    @@instances = {}
    Config[:servers].each do |k, v|
      v[:key] = k
      @@instances[k] = BotInstance.new(v, @@userdb, @@chandb)
      @@instances[k].start
    end
  end

  # Joins the remaining threads until the bot
  # is ready to die.
  #
  # @return [nil] Nil
  def self.wait_until_death
    @@instances.each_value do |value|
      value.thread.join
    end
  end

  # Retrieves a bot instance.
  #
  # @param [Symbol] The symbol of the instance.
  # @return [BotInstance] The instance.
  def self.instance(key)
    return @@instances[key]
  end

  # Iterates through the servers.
  #
  # @param [Block] The block to receive the servers.
  # @return [nil] Nil
  def self.each(&blk)
    @@instances.each do |k, v|
      yield v
    end
  end

  # Gets the user database for the bot.
  #
  # @return [UserDb] The user database.
  def self.userdb
    @@userdb
  end

  # Gets the channel database for the bot.
  #
  # @return [ChannelDb] The channel database.
  def self.chandb
    @@chandb
  end
end

if __FILE__ == $0
  Thread.abort_on_exception = true
  Log::set_provider StdoutProvider.new()
  Bot::read_config
  Bot::read_databases
  Bot::start
  loop do
    cmd = gets.chomp
    break if cmd == 'quit'
    split = cmd.split
    server = split[0].to_sym
    if server != nil
      instance = Bot::instance(server)
      if instance != nil
        instance.server.write(split[1...split.length].join(' '))
      end
    end
  end

  Bot::each do |s|
    s.halt
  end

  Bot::wait_until_death
end

