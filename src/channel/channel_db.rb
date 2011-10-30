# This class holds all the channels
class ChannelDb
  # Creates a new channel db.
  #
  # @return [ChannelDb] The new channel db.
  def initialize()
    @servers = {}
  end

  # Adds a channel to the database
  #
  # @param [Channel] The channel to add.
  # @return [nil] Nil
  def add(channel)
    unless @servers.has_key?(channel.server_key)
      @servers[channel.server_key] = {channel.name => channel}
    else
      @servers[channel.server_key][channel.name] = channel
    end
  end

  # Retrieves a channel object from the db.
  #
  # @param [Symbol] The server to look up.
  # @param [String] The name of the channel.
  def [](server_key, name)
    name = name.downcase
    if @servers.has_key?(server_key)
      return @servers[server_key][name]
    end

    return nil
  end

  # Prepares the channel database for serialization
  # by jettisoning useless state channels.
  #
  # @return [nil] Nil
  def prepare_for_serialization
    new_servers = {}
    @servers.each do |server_key, server|
      new_channels = {}
      server.each do |name, channel|
        new_channels[name] = channel if channel.explicit
      end

      new_servers[server_key] = new_channels if new_channels.count > 0
    end
    @servers = new_servers
  end
end

