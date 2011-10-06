require_relative '../src/extension'

class Test_2 < Extension
  def ext_load
    event :privmsg, :privmsg
    function :public, :somecmd, 'info'
  end

  def somecmd(args)
    
  end

  def privmsg(args)
    nick = args[:from].match(/([a-z]+)!/i)[1]
    raw irc.notice(nick, 'Hey buddy!')
  end
end

