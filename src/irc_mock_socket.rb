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

  def gets
    return "PING :00293923823" if @state == :user
    return ''
  end

  def readlines
    return ["PING :00293923823"] if @state == :user
    return ''
  end

  def close
    
  end

  def remote_address
    self
  end

  def ip_address
    '64.31.0.226'
  end

  def ip_port
    6667
  end

  def canonname
    'irc.gamesurge.net'
  end
end
