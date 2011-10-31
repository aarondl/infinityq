require_relative 'irc_protocol_file_factory'
require_relative 'channel/channel'
require_relative 'user/user'
require_relative 'exceptions'
require_relative 'token_generator'

# The Irc ProtoEvent class
# This class is responsible for all protocol parsing
class IrcProtoEvent
  # This class is a dummy class for injecting
  # raw creation helpers into. It somewhat limits
  # the scope extensions can play with.
  class Helper; end

  # The pseudo events created by the IrcProtoEvent class.
  Pseudo = [:raw, :connect, :disconnect]

  # The list of valid channel prefixes
  ChannelPrefix = ['#']

  # Creates a new IrcProtoEvent instance
  #
  # Reads in a .proto file
  # @param [String] A path to a .proto file to read.
  # @param [UserDb] A user database object.
  # @param [ChannelDb] A channel database object.
  # @param [Symbol] The server key to access the databases.
  # @return [IrcProtoEvent] An irc proto event instance.
  def initialize(filename, userdb, chandb, server_key)
    @userdb = userdb
    @chandb = chandb
    @server_key = server_key
    @events = {}
    create_pseudo_events
    @helper = Helper.new()
    parse_file(filename)
  end

  # Clears the entire event spectrum
  #
  # This method clears all the event data
  # including event handler registration and lexer rules.
  #
  # @param [Bool] If true removes the events as well as the callbacks.
  # @return [nil] Nil
  def clear(kill_events = false)
    if kill_events
      clear_events
    else
      clear_callbacks
    end
  end

  # Parses irc protocol to dispatch events.
  #
  # @param [String] A string containing irc protocol
  # @return [nil] Nil
  def parse_proto(irc_proto_msg)
    parts = irc_proto_msg.split
    from_msg = parts[0].chr == ':'
    offset = from_msg ? 1 : 0
    
    event = to_valid_event(parts[offset])
    if has_event?(event)
      event = @events[event]
      if event.has_key?(:callbacks) && !event[:callbacks].empty?
        dispatch(event, from_msg, parts)
      end
    end

    unless @events[:raw][:callbacks].empty?
      dispatch_raw(@events[:raw], from_msg, irc_proto_msg)
    end 
  end

  # Fires event handlers for pseudo events. Also
  # all other events. But don't tell anyone. 
  #
  # @param [Hash] The arguments to pass to the pseudo # event.
  # @return [nil] Nil
  def fire_pseudo(event, args)
    if has_event?(event)
      event = @events[event]
      if event.has_key?(:callbacks) && !event[:callbacks].empty?
        event[:callbacks].each_value do |callback|
          callback.call args
        end
      end
    end
  end

  # Registers a callback on the event.
  #
  # @param [String, Integer, Symbol] The object specifying the event.
  # @param [Proc, Lambda, Method] The method to call once the event is processed.
  # @return [Array<Object>] Token with which to unregister the callback. Nil if invalid event.
  def register(event, callback)
    event = to_valid_event(event)
    if has_event?(event)
      token = [event, TokenGenerator::generate_token]
      @events[token[0]][:callbacks][token[1]] = callback
      return token
    end
    return nil
  end

  # Unregisters a callback.
  #
  # @param [String] Token that was returned from register.
  # @return [nil] Nil
  def unregister(token)
    @events[token[0]][:callbacks].delete token[1]
  end

  # Provides the names of the arguments passed
  # by the privmsg event if it exists.
  #
  # @return [Array<Symbol>] The names of the position based arguments
  def privmsg_args?
    if @events.has_key?(:privmsg)
      return [
        @events[:privmsg][:rules][0][:name],
        @events[:privmsg][:rules][1][:name]
      ]
    end
    return nil
  end
  
  # Provides the names of the arguments passed
  # by the notice event if it exists.
  #
  # @return [Array<Symbol>] The names of the position based arguments
  def notice_args?
    if @events.has_key?(:notice)
      return [
        @events[:notice][:rules][0][:name],
        @events[:notice][:rules][1][:name]
      ]
    end
    return nil    
  end

  # Checks if the IrcProtoEvent has an event
  #
  # @param [Symbol, String, Fixnum] An event name
  # @return [Bool] If it has_event
  def has_event?(event)
    @events.has_key?(to_valid_event(event))
  end

  # Gets the number of events.
  #
  # @return [Fixnum] The number of events in this IrcProtoEvent instance.
  def event_count(event = nil)
    return @events.count if event == nil
    
    event = @events[to_valid_event(event)]
    return 0 if event.has_key?(:callbacks) == false
    return event[:callbacks].count
  end

  # Gets the related helper instance for this IrcProtoEvent
  attr_reader :helper
  attr_reader :server_key

  protected

  # Creates pseudo events not present in the proto file.
  #
  # @return [nil] Nil
  def create_pseudo_events
    Pseudo.each do |ev|
      @events[ev] = {callbacks: {}}
    end
  end

  # Clears the callbacks for all events.
  #
  # @return [nil] Nil
  def clear_callbacks
    @events.each do |event, eventobj|
      eventobj[:callbacks].clear
    end
  end

  # Clears all events except the pseudo events.
  #
  # @return [nil] Nil
  def clear_events
    save = {} 
    Pseudo.each do |ev|
      save[ev] = @events[ev]
    end
    @events.each_key do |ev|
      next if Pseudo.include?(ev)
      degenerate_helper(ev)
    end
    @events.clear
    save.each do |ev, val|
      @events[ev] = val
    end
  end

  # Dispatches events to the callbacks
  # registered for that event.
  #
  # @param [Hash] The hash event object.
  # @param [Bool] If the first argument is a host.
  # @param [Array<String>] The parts of the message.
  # @return [nil] Nil
  def dispatch(event, from_msg, parts)
    offset = from_msg ? 2 : 1
    args = {}

    set_context = false
    if from_msg
      host = parts[0][1...parts[0].length]
      user = @userdb.find(host)
      if user.nil?
        user = User.new()
        @userdb.add(user)
      end
      if user[@server_key].nil?
        user.add_server(@server_key)
        user[@server_key].set_state(host)
      end
      args[:from] = user
      set_context = true
    end

    if set_context
      args[:from].set_context(@server_key)
    end

    if event.has_key?(:rules)
      pull_args(event[:rules], parts, args, set_context, offset)
    end

    event[:callbacks].each_value do |callback|
      callback.call args
    end

    if set_context
      args[:from].set_context
    end
  end

  # Dispatches the special raw event.
  #
  # @param [Hash] The hash event object.
  # @param [Bool] If the first argument is a host.
  # @param [String] The Irc protocol message.
  # @return [nil] Nil
  def dispatch_raw(event, from_msg, irc_proto_msg)
    args = {}

    if from_msg
      index = irc_proto_msg.index(' ')
      args[:from] = irc_proto_msg[1...index]
      args[:raw] = irc_proto_msg[index+1...irc_proto_msg.length]
    else
      args[:raw] = irc_proto_msg
    end

    event[:callbacks].each_value do |callback|
      callback.call args
    end
  end

  # Pulls arguments based on the event rules
  # from an irc protocol string and puts them into a provided hash
  #
  # @param [Array<Hash>] Rule hashes in an array.
  # @param [Array<String>] A string-split of the irc message.
  # @param [Hash] The arguments to append to.
  # @param [Bool] Whether or not to set channel contexts.
  # @param [Fixnum] The offset into the args list.
  # @return [nil] Nil
  def pull_args(rules, parts, args, set_context, offset = 0)
    rules.each do |rule|

      name = rule[:name]

      case rule[:rule]
      when :single
        raise ProtocolParseError, parts.join(' ') if offset >= parts.length
        args[name] = parts[offset]
        offset += 1
      when :csvlist
        raise ProtocolParseError, parts.join(' ') if offset >= parts.length
        args[name] = parts[offset].split(',')
        offset += 1
      when :channel
        raise ProtocolParseError, parts.join(' ') if offset >= parts.length
        channel = parts[offset]
        if is_channel?(channel)
          channel = lookup_channel(channel)
          if set_context
            if args[:from][@server_key].channels != nil && args[:from][@server_key].channels.include?(channel.name)
              args[:from].set_context(server_key, channel.name)
            end
          end
        end
        args[name] = channel
        offset += 1
      when :chanlist
        raise ProtocolParseError, parts.join(' ') if offset >= parts.length
        channel_names = parts[offset].split(',')
        channels = []
        channel_names.each do |chan|
          channels.push(lookup_channel(chan))
        end
        args[name] = channels
        offset += 1
      when :remaining
        raise ProtocolParseError, parts.join(' ') if offset >= parts.length
        parts[offset] = parts[offset][1...parts[offset].length]
        args[name] = parts[offset...parts.length].join(' ')
        return
      when :optional
        if offset >= parts.length
          args[name] = nil
        else
          args[name] = pull_args(rule[:args], parts[offset...parts.length], args, set_context)
          offset += 1
        end
      else
        raise ProtocolParseError, parts.join(' ')
      end
    end
  end

  # Returns a symbol that represents this event.
  #
  # @param [String, Integer, Symbol] An object that specifies an event.
  # @return [Symbol] A symbol that represents this event.
  def to_valid_event(event)
    if event.kind_of?(String)
      event.downcase!
      event = 'e' + event if event.to_i != 0
    elsif event.kind_of?(Integer)
      event = 'e' + event.to_s
    end
    return event.to_sym
  end

  # Parses a .proto file
  #
  # @param [String] The path to a .proto file to read
  # @return [nil] Nil
  def parse_file(filename)
    file = IrcProtocolFileFactory.get_file(filename)
    file.readlines.each do |line|
      parse_event line.chomp
    end
  end

  # Parses a single event line from a .proto file
  #
  # This method adds events to the events table.
  # @param [String] The event line to parse.
  # @return [nil] Nil
  def parse_event(string)
    raise ArgumentError.new if string.nil? or string.empty?
    args = string.split

    if args.length == 0 || !args[0].match(/^([0-9]+|[a-z]+)$/i)
      raise ProtocolFormatError, args.to_s
    end

    event = {callbacks: {}}

    if args.length > 1
      rules = parse_args(args[1...args.length].flatten)
      return nil if rules.nil?
      event[:rules] = rules
    end

    key = to_valid_event(args[0])
    generate_helper(key, event)
    @events.store key, event
  end

  # Dynamically attaches a helper method with the
  # name eventname() with appropriate arguments
  # to this instance's Helper
  #
  # @param [Symbol] The event name.
  # @param [Hash] The event hash.
  # @return [nil] Nil
  def generate_helper(eventname, eventobj)
    arglist = ''
    body = 'return "' + eventname.to_s.upcase + '"'

    if eventobj.has_key?(:rules) && eventobj[:rules].length > 0
      rules = eventobj[:rules]
      arglist += '('
      optional = false
      first = true
      i = 0
      while i < rules.length
        rule = rules[i]
        prefix = suffix = ''
        case rule[:rule]
        when :csvlist, :chanlist
          suffix = ".join(',')"
        when :remaining
          prefix = ':'
        when :optional
          optional = true
          i = 0
          rules = rule[:args]
          next
        end
        arglist += ', ' unless first
        arglist += "#{rule[:name].to_s}"
        arglist += (optional ? "=''" : '')
        if optional
          body += " + (#{rule[:name].to_s}.empty? ? '' : ' #{prefix}' + #{rule[:name]}#{suffix})"
        else
          body += " + ' #{prefix}' + #{rule[:name]}#{suffix}"
        end
      first = false
      i += 1
      end
      arglist += ')'
    end

    eval("def @helper.#{eventname.to_s}#{arglist}; #{body}; end")
  end

  # Dynamically destroys a helper method with the name
  # eventname() from this instance of IrcProtoEvent
  #
  # @param [Symbol] The event name to degenerate the helper for.
  # @return [nil] Nil
  def degenerate_helper(eventname)
    if @helper.respond_to?("#{eventname.to_s}")
      eval("class << @helper; remove_method(:#{eventname.to_s}); end")
    end
  end

  # Parses the arguments list of an event line.
  #
  # @param [Array<String>] A space-split string of rules.
  # @return [Array<Hash>] The lexer rules for the arguments to the event line.
  def parse_args(args)
    rules = []

    i = 0
    while i < args.length
      arg = args[i]

      if arg.start_with?('[')
        rule, i = get_optional_argument(args, i)
        rules.push rule
      else
        rules.push get_non_optional_rule(arg)
      end

      i += 1
    end

    return rules
  end

  # Checks to make sure that the channel name
  # follows the naming conventions for channels
  # according to the ChannelPrefix array.
  #
  # @param [String] Channel name
  # @return [Bool] Whether or not it's a valid channel
  def is_channel?(name)
    ChannelPrefix.each do |prefix|
      if name.start_with?(prefix)
        return true
      end
    end
    return false
  end

  # Looks up a channel in the channel database
  #
  # @param [String] Channel name.
  # @return [Channel] The channel object
  def lookup_channel(name)
    channel = @chandb[@server_key, name]
    if channel.nil?
      channel = Channel.new(@server_key, name)
      @chandb.add(channel)
    end
    return channel
  end

  # Gets the rules for optional arguments
  #
  # @param [String] The argument list.
  # @param [Integer] The index of the argument containing the '['
  # @return [Hash, Integer] The rule as well as the new value of i.
  def get_optional_argument(args, i)
    j = 0
    while j < args.length
      if args[j].end_with?(']')
        args[i] = args[i][1...args[i].length]
        args[j] = args[j][0...args[j].length-1]
        return {rule: :optional, args: parse_args(args[i..j])}, j + 1
      end
      j += 1
    end
  end

  # Gets the rule for a non-optional argument.
  #
  # @param [String] The argument to parse.
  # @return [Hash] The rule hash to append.
  def get_non_optional_rule(arg)
    type = :single
    if arg.start_with?(':')
      type = :remaining
      arg = arg[1...arg.length]
    end
    if arg.start_with?('*')
      raise ProtocolFormatError, arg if type == :remaining
      type = :csvlist
      arg = arg[1...arg.length]
    end
    if arg.start_with?('#')
      raise ProtocolFormatError, arg if type == :remaining
      case type
      when :single
        type = :channel
      when :csvlist
        type = :chanlist
      end
      arg = arg[1...arg.length]
    end

    if arg.match(/^[a-z]+$/i)
      return {rule: type, name: arg.to_sym}
    else
      raise ProtocolFormatError, arg
    end
  end
end

