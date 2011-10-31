$nasty_test = nil

class Test1 < Extension
  def ext_load
    $nasty_test = @cfg[:test]
  end
  def ext_unload
    $nasty_test = :unload
  end
end

