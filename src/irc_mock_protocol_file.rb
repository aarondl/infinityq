class IrcMockProtocolFile
  def close  
  end

  def readlines
    return [
      "PRIVMSG 1 :\r\n",
      "NOTICE 1 :\r\n",
      "MODE 2 [3]\r\n",
      "TOPIC 1 [1]\r\n",
      "NAMES [*1]\r\n",
      "LIST [*1 [1]]\r\n",
      "INVITE [2]\r\n",
      "KICK *2 [1]\r\n"
    ]
  end
end
