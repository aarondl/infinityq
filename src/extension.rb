require_relative 'irc_proto_event'

# This class is the base class for all extensions.
class Extension
  # Creates a new Extension with access to the
  # current connections IrcProtoEvent instance.
  #
  # @param [IrcProtoEvent] The IrcProtoEvent for the connection.
  # @return [Extension] A new extension.
  def initialize(irc_proto, func_registrar)
    @irc_proto = irc_proto
    @func_registrar = func_registrar
    @tokens = []
    if respond_to?(:ext_load)
      ext_load
    end
  end

  # Registers an event for this extension.
  # Ensuring that the token is kept for unregistration.
  #
  # @param [Symbol, String] The event to register.
  # @param [Symbol] The callback method.
  # @return [nil] Nil
  def event(type, method)
    @tokens.push @irc_proto.register(type, self.method(method))
    return nil
  end

  # Registers function for this extension.
  # Ensuring that the token is kept for unregistration.
  #
  # @param [Symbol] The type of message (:public/:private/:notice)
  # @param [Symbol] The callback method.
  # @param [String, RegExp] A matcher that must pass for the function to fire.
  # @return [nil] Nil
  def function(msgtype, method, matchspec)
    @tokens.push @func_registrar.register(msgtype, self.method(method), matchspec)
    return nil
  end

  def unload
    @tokens.each do |tok|
      @irc_proto.unregister(tok)
    end
  end
end

