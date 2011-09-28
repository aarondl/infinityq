# Used to mock a protocol file
class IrcMockProtocolFile
  # Closes the mock protocol file
  #
  # @return [nil] Nil
  def close  
  end

  # Mocks the file's readlines method
  #
  # @see File#readlines
  # @return [Array<String>] An array of strings
  def readlines
    return [
      "PRIVMSG user :msg\r\n",
      "NOTICE user :msg\r\n",
      "MODE modestr [limit] [user] [banmask]\r\n",
      "TOPIC channel [topic]\r\n",
      "NAMES [*channellist]\r\n",
      "LIST [*channellist [server]]\r\n",
      "INVITE [nickname] [channel]\r\n",
      "KICK *channellist *nicklist [comment]\r\n"
    ]
  end
end

