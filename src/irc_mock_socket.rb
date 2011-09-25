class IrcMockSocket
  def initialize(address, port)
    @state = :init
  end

  def write(data)
    if data.match /NICK \w+\r\n/
      @state = :nick
    elsif @state == :nick && data.match(/USER \w+ [0-9]+ (\*|\w+) :\w+\r\n/)
      @state = :user
    end
  end

  def read
    return "PING :00293923823\r\n" if @state == :user
    return ''
  end
end
