require_relative 'irc_server'
require_relative 'irc_proto_event'
require_relative 'core_events'
require_relative 'function_registrar'
require_relative 'extension_host'

# This class ties all the classes together
# to create a bot instance.
class BotInstance
  # Reads a config chunk to factory-create
  # classes satisfying all class dependencies.
  #
  # @param [Hash] The configuration to use.
  # @param [UserDb] A user database.
  # @param [ChannelDb] A channel database.
  # @param [Store] The extension database.
  # @return [BotInstance] A new BotInstance.
  def initialize(c, userdb, chandb, extdb)
    @server = IrcServer.new c[:address], c[:port]
    @proto = IrcProtoEvent.new c[:proto], userdb, chandb, c[:key]
    @core_events = CoreEvents.new @server, @proto, c[:nick],
      c[:altnick], c[:email], c[:name]
    @fn_registrar = FunctionRegistrar.new @proto, c[:extprefix]
    @exthost = ExtensionHost.new c[:extpath], 
      c[:extensioncfg], extdb, @server, @proto, @fn_registrar, userdb, chandb
    @key = c[:key]

    @config = c
    @halt = false

    @exthost.load_extensions *c[:extensions]
  end

  # Starts this instance by creating a reading thread.
  #
  # @return [nil] Nil
  def start
    @thread = Thread.new {
      @server.connect
      @proto.fire_pseudo(:connect, {address: @server.address?, port: @server.port?})
      protos = @server.read
      while protos != nil && @halt != true
        protos.each do |proto|
          Log::write proto
          @proto.parse_proto(proto)
        end
        protos = @server.read
      end
    }
  end

  # Halts this BotInstance.
  #
  # @return [nil] Nil
  def halt
    @halt = true
    @server.disconnect
    @thread.exit
  end

  attr_reader :server, :proto, :core_events
  attr_reader :fn_registrar, :exthost, :key, :thread
end

