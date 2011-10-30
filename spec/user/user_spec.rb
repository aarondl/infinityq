require_relative '../../src/user/user'

describe "User" do
  before :each do
    @host = /.*@b.?tforge\.ca/
    @u = User.new
    @u.add_host(@host)
  end

  it "should add unique hosts" do
    @u.add_host(@host)
    @u.each_host do |h|
      h.should eq(@host)
      h.should be_kind_of(Regexp)
    end
    @u.add_host('.*@lol\.com')
    @u.hosts_count.should eq(2)
  end

  it "should remove hosts" do
    @u.remove_host(@host)
    @u.hosts_count.should eq(0)
  end

  it "should keep a global access" do
    @u.global_access.power.should be_zero
  end

  it "should be able to be marked as explicit" do
    @u.explicit.should be_false
    @u.explicit = true
    @u.explicit.should be_true
  end

  context "when it has some server access for :gamesurge" do
    before :each do
      @u.add_server(:gamesurge, 50, Access::A)
    end

    context "when it has channel access for #C++" do
      before :each do
        @u[:gamesurge].add_channel('#C++', 100, Access::C)
      end

      it "should wipe all states" do
        @u[:gamesurge].set_state('~Aaron@bitforge.ca', 'Aaron L', ['#C++', '#blackjack'])
        @u[:gamesurge]['#C++'].set_state 'o'
        @u.wipe_all_state
        @u[:gamesurge].online?.should be_false
        @u[:gamesurge]['#C++'].online?.should be_false
      end

      it "should set channel state" do
        c = @u[:gamesurge]['#C++']
        c.online?.should be_false
        c.set_state 'ov'
        c.each_mode do |m|
          m.should match(/[ov]/)
        end
        c.has_mode?('o').should be_true
        c.online?.should be_true
        c.wipe_state
        c.online?.should be_false
      end

      it "should allow removal of a channel" do
        @u[:gamesurge].remove_channel('#C++')
        @u[:gamesurge]['#C++'].should be_nil
      end

      it "should allow context setting" do
        @u.global_access.power = 10
        @u.set_context(:gamesurge)
        (@u.access == 50).should be_true
        @u.set_context(:gamesurge, '#C++')
        (@u.access == 100).should be_true 
        @u.set_context
        (@u.access == 10).should be_true
      end

      it "should die on bad context sets" do
        expect {
          @u.set_context(:lol)
        }.to raise_error(StandardError)
        expect {
          @u.set_context(:gamesurge, 'ROFL')
        }.to raise_error(StandardError)
      end

      it "should contain access for channels the user has access to" do
        (@u[:gamesurge]['#C++'].access == 100).should be_true
        @u[:gamesurge]['#C++'].access[Access::C].should be_true
      end
    end

    it "should contain access for servers the user has access to" do
      (@u[:gamesurge].access == 50).should be_true
      @u[:gamesurge].access[Access::A].should be_true
    end

    it "should set server state" do
      s = @u[:gamesurge]
      s.online?.should be_false
      s.set_state('~Aaron@bitforge.ca', 'Aaron L', ['#C++', '#blackjack'])
      s.nick.should eq('Aaron')
      s.host.should eq('bitforge.ca')
      s.realname.should eq('Aaron L')
      s.fullhost.should eq('~Aaron@bitforge.ca')
      s.channels.should include('#c++', '#blackjack')
      s.online?.should be_true
    end

    it "shouldn't require all state" do
      s = @u[:gamesurge]
      s.set_state('~Aaron@bitforge.ca')
      s.nick.should eq('Aaron')
      s.host.should eq('bitforge.ca')
    end

    it "should wipe server state" do
      s = @u[:gamesurge]
      s.wipe_state
      s.nick.should be_nil
      s.host.should be_nil
      s.realname.should be_nil
      s.fullhost.should be_nil
      s.channels.should be_nil
      s.online?.should be_false
    end

    it "should remove servers" do
      @u.remove_server(:gamesurge)
      @u[:gamesurge].should be_nil
    end
  end

end

