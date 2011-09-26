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
    parse_file(filename)
  end

  # Clears the entire event spectrum
  #
  # This method clears all the event data
  # including event handler registration and lexer rules.
  def clear
    @events.clear
  end

  # Checks if the IrcProtocol has an event
  #
  # @param [Symbol, String, Fixnum] An event name
  # @return [Bool] If it has_event
  def has_event?(event)
    if event.kind_of?(String)
      event.downcase!
      event = 'i' + event if event.to_i != 0
      event = event.to_sym
    end
    
    @events.has_key?(event)
  end

  # Gets the number of events.
  #
  # @return [Fixnum] The number of events in this IrcProtocol instance.
  def event_count
    @events.count
  end

  protected

  # Parses a .proto file
  #
  # @param [String] The path to a .proto file to read
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
  def parse_event(string)
    raise ArgumentError.new if string.nil? or string.empty?
    args = string.split

    if args.length == 0 || !args[0].match(/^([0-9]+|[a-z]+)$/i)
      raise ProtocolFormatError, args.to_s
    end

    event = {}

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

        j = 0
        while j < args.length
          if args[j].end_with?(']')
            args[i] = args[i][1...args[i].length]
            args[j] = args[j][0...args[j].length-1]
            rules.push({ :rule => :optional, :args => parse_args(args[i..j]) })
            i = j + 1
            break
          end
          j += 1
        end

      else
        csv = false
        if arg.start_with?('*')
          csv = true
          arg = arg[1...arg.length]
        end

        int = arg.to_i
        if int != 0
          int.times do rules.push({:rule => (csv ? :csvlist : :single)}) end
        elsif arg == ':'
          rules.push({:rule => :remaining})
        else
          raise ProtocolFormatError, args.to_s
        end
      end

      i += 1
    end

    return rules
  end
end

