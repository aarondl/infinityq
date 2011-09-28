require 'uuid'
require_relative 'irc_protocol_file_factory'
require_relative 'exceptions'

# The Irc Protocol class
# This class is responsible for all protocol parsing
class IrcProtocol
  # Creates a new IrcProtocol class
  #
  # Reads in a .proto file
  # @param [String] A path to a .proto file to read.
  def initialize(filename)
    @events = {}
    @events[:raw] = {:callbacks => {}}
    parse_file(filename)
  end

  # Clears the entire event spectrum
  #
  # This method clears all the event data
  # including event handler registration and lexer rules.
  # @return [nil] Nil
  def clear
    saveraw = @events[:raw]
    @events.clear
    @events[:raw] = saveraw
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

  # Registers a callback on the event.
  #
  # @param [String, Integer, Symbol] The object specifying the event.
  # @param [Proc, Lambda, Method] The method to call once the event is processed.
  # @return [Array<Object>] Token with which to unregister the callback. Nil if invalid event.
  def register(event, callback)
    event = to_valid_event(event)
    if has_event?(event)
      token = [event, generate_token.to_sym]
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

  # Checks if the IrcProtocol has an event
  #
  # @param [Symbol, String, Fixnum] An event name
  # @return [Bool] If it has_event
  def has_event?(event)
    @events.has_key?(to_valid_event(event))
  end

  # Gets the number of events.
  #
  # @return [Fixnum] The number of events in this IrcProtocol instance.
  def event_count
    @events.count
  end

  protected

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

    args[:from] = parts[0][1...parts[0].length] if from_msg

    if event.has_key?(:rules)
      pull_args(event[:rules], parts, args, offset)
    end

    event[:callbacks].each_value do |callback|
      callback.call args
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
  # @return [nil] Nil
  def pull_args(rules, parts, args, offset = 0)
    rules.each do |rule|
      name = rule[:name]
      case rule[:rule]
      when :single
        args[name] = parts[offset]
        offset += 1
      when :csvlist
        args[name] = parts[offset].split(',')
        offset += 1
      when :remaining
        parts[offset] = parts[offset][1...parts[offset].length]
        args[name] = parts[offset...parts.length].join(' ')
      when :optional
        if offset >= parts.length
          args[name] = nil
        else
          args[name] = pull_args(rule[:rules], parts[offset...parts.length], args)
          offset += 1
        end
      else
        raise ProtocolParseError, parts.flatten
      end
    end
  end

  # Generates a randomized token to uniquely identify
  # event registrations.
  #
  # @return [Symbol] A randomized unique token.
  def generate_token
    @uuid ||= UUID.new
    guid = @uuid.generate :compact
    while guid.length >= 16 && guid.match(/^[0-9]/)
      guid = guid[1...guid.length]
    end
    return generate_token if guid.length < 16
    return guid.to_sym
  end

  # Returns a symbol that represents this event.
  #
  # @param [String, Integer, Symbol] An object that specifies an event.
  # @return [Symbol] A symbol that represents this event.
  def to_valid_event(event)
    if event.kind_of?(String)
      event.downcase!
      event = 'i' + event if event.to_i != 0
    elsif event.kind_of?(Integer)
      event = 'i' + event.to_s
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

    event = {:callbacks => {}}

    if args.length > 1
      rules = parse_args(args[1...args.length].flatten)
      return nil if rules.nil?
      event[:rules] = rules
    end

    key = args[0].to_i == 0 ? args[0].downcase : 'i' + args[0]
    @events.store key.to_sym, event
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
        return {:rule => :optional, :args => parse_args(args[i..j])}, j + 1
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

    if arg.match(/^[a-z]+$/i)
      return {:rule => type, :name => arg.to_sym}
    else
      raise ProtocolFormatError, arg
    end
  end
end

