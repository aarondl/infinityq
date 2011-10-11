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
  def initialize(config)
    @server = IrcServer.new config[:address], config[:port]
    @proto = IrcProtoEvent.new config[:proto]
    @core_events = CoreEvents.new @server, @proto, config[:nick],
      config[:altnick], config[:email], config[:name]
    @fn_registrar = FunctionRegistrar.new @proto, config[:extprefix]
    @exthost = ExtensionHost.new config[:extpath], @server, @proto, @fn_registrar
    @key = config[:key]

    @config = config
    @halt = false

    @exthost.load_extensions *config[:extensions]
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

