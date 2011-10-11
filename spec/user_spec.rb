require_relative '../src/user'

describe "User" do
  before :each do
    @nick = 'Aaron'
    @host = '~Aaron@mer.user.gamesurge'
    @u = User.new(@nick, @host)
  end

  it "should provide details about the user" do
    @u.host.should eq(@host)
    @u.nick.should eq(@nick)
    @u.user.should eq(@nick)
  end

end

