require 'yaml'
require_relative 'log'
require_relative 'stdout_provider'
require_relative 'bot_instance'
require_relative 'exceptions'
require_relative 'store'
require_relative 'channel/channel_db'
require_relative 'user/user_db'
require_relative 'file_factory'

# Ruby IRC Bot main class
class Bot
  # The static config path to the config file
  ConfigPath = 'config.yml'
  # The static database path to the database files
  DbPath = './db/'
  # The file name for the channel database.
  ChanDbFile = 'channels.db'
  # The file name for the user database.
  UserDbFile = 'users.db'
  # The file name for the extension storage database.
  ExtensionDbFile = 'extension.db'
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

    cascading = [:extensions, :extensioncfg, :extprefix, :extpath, :proto, :nick, :altnick, :name, :email]
    Config[:servers].each do |k, v|
      cascading.each do |attrib|
        if Config.has_key?(attrib) && v.has_key?(attrib) == false
          v[attrib] = Config[attrib]
        end
      end
    end
  end

  # Opens file handles for the database files.
  #
  # @param [Block] A block that uses the file handles.
  # @return [nil] Nil
  def self.prep_db_read(&blk)
    userio = FileFactory.exists?(DbPath + UserDbFile) ? FileFactory.create(DbPath + UserDbFile) : nil
    chanio = FileFactory.exists?(DbPath + ChanDbFile) ? FileFactory.create(DbPath + ChanDbFile) : nil
    extio = FileFactory.exists?(DbPath + ExtensionDbFile) ? FileFactory.create(DbPath + ExtensionDbFile) : nil
    yield userio, chanio, extio
    userio.close unless userio.nil?
    chanio.close unless chanio.nil?
    extio.close unless extio.nil?
  end

  # Reads the user and channel database if available.
  #
  # @param [IO] The io object to read the user database from.
  # @param [IO] The io object to read the channel database from.
  # @param [IO] The io object to read the extension database from.
  # @return [nil] Nil
  def self.read_databases(userio, chanio, extio)
    unless userio.nil?
      @@userdb = Marshal::load(userio.read())
    else
      @@userdb = UserDb.new()
    end

    unless chanio.nil?
      @@chandb = Marshal::load(chanio.read())
    else
      @@chandb = ChannelDb.new()
    end

    unless extio.nil?
      @@extdb = Marshal::load(extio.read())
    else
      @@extdb = Store.new()
    end
  end

  # Opens file handles for the database files.
  #
  # @param [Block] A block that uses the file handles.
  # @return [nil] Nil
  def self.prep_db_write(&blk)
    unless Dir::exist?(DbPath)
      Dir::mkdir(DbPath)
    end

    userio = FileFactory.create(DbPath + UserDbFile, 'w+')
    chanio = FileFactory.create(DbPath + ChanDbFile, 'w+')
    extio = FileFactory.create(DbPath + ExtensionDbFile, 'w+')
    yield userio, chanio, extio
    userio.close
    chanio.close
    extio.close
  end

  # Saves the databases to files
  #
  # @param [IO] An IO object to save the user database with
  # @param [IO] An IO object to save the channel database with
  # @param [IO] An IO object to save the extension database with
  # @return [nil] Nil
  def self.save_databases(userio, chanio, extio)
    @@userdb.prepare_for_serialization
    userio.write(Marshal::dump(@@userdb))
    @@chandb.prepare_for_serialization
    chanio.write(Marshal::dump(@@chandb))
    extio.write(Marshal::dump(@@extdb))
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
      @@instances[k] = BotInstance.new(v, @@userdb, @@chandb, @@extdb)
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

  # Gets the extension database for the bot.
  #
  # @return [Hash] The extension database.
  def self.extdb
    @@extdb
  end
end

if __FILE__ == $0
  Thread.abort_on_exception = true
  Log::set_provider StdoutProvider.new()
  Bot::read_config
  Bot::prep_db_read do |u, c, e|
    Bot::read_databases u, c, e
  end
  Bot::start
  loop do
    cmd = gets.chomp
    case cmd
    when 'quit'
      break
    when 'du'
      puts YAML::dump(Bot::userdb)
      next
    when 'dc'
      puts YAML::dump(Bot::chandb)
      next
    when 'de'
      puts YAML::dump(Bot::extdb)
      next
    when /^rl ([a-z_0-9]+)/i
      puts "Reloading #{$1}"
      Bot::each do |botinstance|
        botinstance.exthost.unload_extensions($1)
        botinstance.exthost.load_extensions($1)
      end
    end

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
  Bot::prep_db_write do |u, c, e|
    Bot::save_databases u, c, e
  end
end

