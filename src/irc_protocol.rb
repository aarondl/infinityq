require_relative 'irc_protocol_file_factory'
require_relative 'exceptions'

class IrcProtocol
  def initialize(filename)
    @events = {}
    parse_file(filename)
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

  def parse_file(filename)
    file = IrcProtocolFileFactory.get_file(filename)
    file.readlines.each do |line|
      parse_event line.chomp
    end
  end

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

