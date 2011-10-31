class Test_2 < Extension
  def ext_load
    function :both, :private, :add_su, 'super_me'
    function :both, :both, :access, 'access'
  end

  def add_su(args)
    user = args[:from]
    return if user == nil

    if db[:test_2] != nil
      if db[:test_2][:su_set] != nil
        raw irc.notice(user.nick, 'Warning: su already set.')
        return
      end
    else
      db[:test_2] = {}
    end

    user.stateonly = false
    user[svr].stateonly = false
    user.add_host(user.fullhost)
    user.global_access.power = 100
    user.global_access.add(*('a'..'z').to_a)

    raw irc.notice(user.nick, 'You are now the super user: ' + user.fullhost)
    db[:test_2][:su_set] = user.fullhost
  end

  def access(args)
    user = args[:from]
    raw irc.notice(user.nick.to_s, "Access: #{user.access.to_s}")
  end
end

