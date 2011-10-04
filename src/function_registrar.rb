require_relative 'token_generator'

# This class registers extension functions
# an abstraction designed to stop so many people
# from writing their own parse code.
class FunctionRegistrar
  # Creates a new Function registrar using IrcProtoEvent
  # as a backing class.
  #
  # @param [IrcProtoEvent] The IrcProtoEvent instance to attach to.
  # @param [String] Function prefix that appears before all functions
  # @return [FunctionRegistrar] The function registrar.
  def initialize(irc_proto, prefix)
    @irc_proto = irc_proto
    @prefix = prefix
    @privmsg_args = irc_proto.privmsg_args?    
    @notice_args = irc_proto.notice_args?
    @privmsg_token = nil
    @notice_token = nil
    @functions = {
      public: {},
      private: {},
      notice: {}
    }
  end

  # Registers a function with the IrcProtoEvent
  # instance.
  #
  # @param [Symbol] The type of message (:public/:private/:notice)
  # @param [Symbol] The callback method.
  # @param [String, RegExp] A matcher that must pass for the function to fire.
  # @return [Array] The unregistration token.
  def register(msgtype, method, matchspec)
    func = @functions[msgtype]
    raise ArgumentError, 'Msgtype must be :public|:private|:notice' if func.nil?

    if msgtype == :notice
      if @notice_token == nil
        @notice_token = 
          @irc_proto.register(get_event(msgtype), self.method(get_method(msgtype)))
      end
    else
      if @privmsg_token == nil
        @privmsg_token =
          @irc_proto.register(get_event(msgtype), self.method(get_method(msgtype)))
      end
    end

    matchspec = Regexp.new('^' + matchspec) if matchspec.kind_of?(String)

    localtoken = TokenGenerator::generate_token
    func[localtoken] = {match: matchspec, callback: method}
    return [msgtype, localtoken]
  end

  # Collapses this instance removing all event
  # handlers from the IrcProtoEvent instance it holds.
  #
  # @return [nil] Nil
  def collapse
    @irc_proto.unregister(@notice_token) unless @notice_token.nil?
    @irc_proto.unregister(@privmsg_token) unless @privmsg_token.nil?
  end

  # Unregisters a function using the token given.
  #
  # @param [Array] The token given by the register function.
  # @return [nil] Nil
  def unregister(token)
    func = @functions[token[0]]
    raise ArgumentError, 'Bad token' if func.nil?
    func.delete(token[1])
  end

  # Event handler for all public and private functions.
  #
  # @param [Hash] The arguments from the irc event.
  # @return [nil] Nil
  def call_privmsg(args)
    argnames = @privmsg_args || [:user, :msg]
    func = @functions[:private]
    func = @functions[:public] if args[argnames[0]].start_with?('#')
    call_callbacks(argnames, func, args)
  end

  # Event handler for all notice functions.
  #
  # @param [Hash] The arguments from the irc event.
  # @return [nil] Nil
  def call_notice(args)
    call_callbacks(@notice_args, @functions[:notice], args)
  end

  def call_callbacks(argnames, func, args)
    argnames = argnames || [:user, :msg]
    msg = args[argnames[1]]
    return unless msg.start_with?(@prefix)
    args = args.clone
    msg = msg[1...msg.length]
    return if msg.empty?

    func.each do |token, registration|
      if msg.match(registration[:match])
        msg = msg.gsub(registration[:match], '')
        msg = msg[1...msg.length] if msg.start_with?(' ')
        args[argnames[1]] = msg
        registration[:callback].call args
      end
    end
  end

  private
  def get_event(type)
    case type
    when :public; return :privmsg
    when :private; return :privmsg
    when :notice; return :notice
    else raise ArgumentError, 'Msgtype must be :public|:private|:notice'
    end
  end

  def get_method(type)
    case type
    when :public, :private; return :call_privmsg
    when :notice; return :call_notice
    else raise ArgumentError, 'Msgtype must be :public|:private|:notice'
    end
  end
end

