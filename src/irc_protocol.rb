require_relative 'irc_protocol_file_factory'
require_relative 'bot_exceptions'

class IrcProtocol
  def initialize(filename)
    @events = {}
    file = IrcProtocolFileFactory.get_file(filename)
    file.readlines.each do |line|
      parse_event line.chomp
    end
  end

  def clear
    @events.clear
  end

  def has_event?(event)
    if event.kind_of?(String)
      event.downcase!
      event = 'i' + event if event.to_i != 0
      event = event.to_sym
    end
    
    @events.has_key?(event)
  end

  def event_count
    @events.count
  end

  protected

  def parse_event(string)
    raise ArgumentError.new if string.nil? or string.empty?
    args = string.split

    if args.length == 0 or !args[0].match(/^([0-9]+|[a-z]+)$/i)
      return ProtocolFormatError, args.to_s
    end

    event = {}

    if args.length > 1
      rules = parse_args(args[1..args.length])
      return nil if rules.nil?
      event[:lex] = rules
    end

    key = args[0].to_i == 0 ? args[0].downcase : 'i' + args[0]
    @events.store key.to_sym, event
  end

  def parse_args(args)
    rules = []

    args.each do |arg|
      int = arg.to_i
      if int != 0
        rules.push({:rule => :single, :args => int})
      elsif arg == ':'
        rules.push({:rule => :remaining})
      else
        raise ProtocolFormatError, args.to_s
      end
    end

    return rules
  end
end

