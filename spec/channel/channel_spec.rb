require_relative '../../src/channel/channel'
require_relative '../../src/user/user'

describe "Channel" do
  before :each do
    @c = Channel.new(:gamesurge, '#C++')

    @user = User.new()
    @user.add_host(/.*@bitforge\.ca/)
    @user.add_server(:gamesurge)
    @user[:gamesurge].set_state('aaron@bitforge.ca', 'Aaron L', ['#c++'])
  end

  it "should have a name" do
    @c.server_key.should eq(:gamesurge)
    @c.name.should eq('#c++')
  end

  it "should have some persistent storage" do
    @c.store(:key, :value)
    @c.fetch(:key).should eq(:value)    
  end

  it "should keep a list of users" do
    @c.add_user(@user)
    @c['aaron'].should eq(@user)
    @c['aaron@bitforge.ca'].should eq(@user)
  end
end

