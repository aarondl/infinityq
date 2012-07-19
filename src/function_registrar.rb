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
    @privmsg_args = irc_proto.privmsg_args? || [:target, :msg]
    @notice_args = irc_proto.notice_args? || [:target, :msg]
    @privmsg_token = nil
    @notice_token = nil
    @functions = {
      privmsg: {public: {}, private: {}, both: {}},
      notice: {public: {}, private: {}, both: {}},
      both: {public: {}, private: {}, both: {}}
    }
  end

  # Registers a function with the IrcProtoEvent
  # instance.
  #
  # @param [Symbol] The type of message (:privmsg/:notice/:both)
  # @param [Symbol] The publicity of the message (:public/:private/:both)
  # @param [Symbol] The callback method.
  # @param [String, RegExp] A matcher that must pass for the function to fire.
  # @param [Hash] Access required (:access, :any_of, :all_of)
  # @return [Array] The unregistration token.
  def register(msgtype, publicity, method, matchspec, access_required = nil)
    func = @functions[msgtype] && @functions[msgtype][publicity]
    raise ArgumentError, 'Msgtype: [:notice|:privmsg|:both], Publicity: [:public|:private|:both]' if func.nil?

    if msgtype == :notice || msgtype == :both
      if @notice_token == nil
        @notice_token = @irc_proto.register(:notice, self.method(:call_notice))
      end
    end
    if msgtype == :privmsg || msgtype == :both
      if @privmsg_token == nil
        @privmsg_token = @irc_proto.register(:privmsg, self.method(:call_privmsg))
      end
    end

    matchspec = Regexp.new('^' + matchspec) if matchspec.kind_of?(String)

    localtoken = TokenGenerator::generate_token

    unless access_required.nil?
      unless access_required[:any_of].nil?
        access_required[:any_of] = access_required[:any_of].downcase.chars.to_a
      end
      unless access_required[:all_of].nil?
        access_required[:all_of] = access_required[:all_of].downcase.chars.to_a
      end
    end

    func[localtoken] = {match: matchspec, callback: method, access_req: access_required}
    return [msgtype, publicity, localtoken]
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
    func = @functions[token[0]][token[1]]
    raise ArgumentError, 'Bad token' if func.nil?
    func.delete(token[2])
  end

  # Event handler for all public and private functions.
  #
  # @param [Hash] The arguments from the irc event.
  # @return [nil] Nil
  def call_privmsg(args)
    find_callbacks(@privmsg_args, :privmsg, args)
  end

  # Event handler for all notice functions.
  #
  # @param [Hash] The arguments from the irc event.
  # @return [nil] Nil
  def call_notice(args)
    find_callbacks(@notice_args, :notice, args)
  end

  # Finds and calls the callbacks with the appropriate arguments.
  #
  # @param [Array<Symbol>] Argument names to pass along.
  # @param [Symbol] The msgtype that the event was invoked from.
  # @param [Hash] The arguments to pass to the callbacks.
  # @return [nil] Nil
  def find_callbacks(argnames, msgtype, args)
    msg = args[argnames[1]]
    return if msg.empty?
    publicity = args[argnames[0]].class == String ? :private : :public
    if publicity == :public
      return unless msg.start_with?(@prefix)
      msg = msg[1...msg.length]
    end

    call_callbacks(
      msg,
      argnames,
      args,
      [msgtype, publicity], [msgtype, :both], [:both, publicity], [:both, :both]
    )
  end

  # Calls the callbacks in a set of functions.
  #
  # @param [String] The message.
  # @param [Array<Symbol>] The argument names.
  # @param [Hash] The args to pass on.
  # @param [Array<Array<Symbol>>] Array of arrays of function combos to call.
  # @return [nil] Nil
  def call_callbacks(msg, argnames, args, *functions)
    functions.each do |combo|
      fns = @functions[combo[0]][combo[1]]

      fns.each do |token, registration|
        if msg.match(registration[:match])
          access_req = registration[:access_req]
          unless access_req.nil?
            next if args[:from].nil?
            next unless has_access?(access_req, args[:from].access)
          end

          msg = msg.gsub(registration[:match], '')
          msg = msg[1...msg.length] if msg.start_with?(' ')
          args = args.clone
          args[argnames[1]] = msg
          registration[:callback].call args
        end
      end
    end
  end

  # Verifies the access of a user to a function.
  #
  # @param [Hash] The access required.
  # @param [Access] The access of the user.
  def has_access?(access_req, access)
    unless access_req[:access].nil?
      return false if access < access_req[:access]
    end
    unless access_req[:any_of].nil?
      return false unless access.has_any?(*access_req[:any_of])
    end
    unless access_req[:all_of].nil?
      return false unless access.has?(*access_req[:all_of])
    end

    return true
  end
end

