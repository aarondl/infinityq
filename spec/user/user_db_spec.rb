require_relative '../../src/user/user_db'
require_relative '../../src/user/user'

describe "UserDb" do
  before :each do
    @u = UserDb.new()

    @host = 'Aaron!~aaron@bitforge.ca' 

    @user = User.new(false)
    @user.add_host(/.*@bitforge\.ca$/)
    @user.global_access.power = 10
    @user.global_access[Access::A]
    @user.add_server(:gamesurge)
    @user[:gamesurge].set_state(@host)


    @u.add(@user)
  end

  it "should keep a list of users it knows about" do
    @u.users.length.should eq(1)
  end

  it "should be able to add a user" do
    @u.users.should include(@user)
  end

  it "should be able to remove a user" do
    @u.remove(@user)
    @u.users.should_not include(@user)
  end

  it "should remove users by host" do
    @u.remove_host(@host)
    @u.users.should_not include(@user)
  end

  it "should be able to find a user based on host" do
    @u.find(@host).should eq(@user)
    @u['lol'].should be_nil
  end

  it "should be able to find a user based on nick" do
    @u.find_by_nick(:gamesurge, 'aaron').should eq(@user)
    @u.find_by_nick(:gamesurge, 'lol').should be_nil
  end

  it "should cache lookups" do
    @u.find(@host).should eq(@user)
    @u.find_by_nick(:gamesurge, 'aaron').should eq(@user)
    @u.instance_variable_get(:@cache).should include(@host)
    @u.instance_variable_get(:@cache)[@host].should eq(@user)
    @u.instance_variable_get(:@nick_cache).should include(:gamesurge)
    @u.instance_variable_get(:@nick_cache)[:gamesurge].should include('aaron')
    @u.instance_variable_get(:@nick_cache)[:gamesurge]['aaron'].should eq(@user)
  end

  it "should be able to flush the cache" do
    @u.find(@host).should eq(@user)
    @u.find_by_nick(:gamesurge, 'aaron').should eq(@user)
    @u.flush_cache
    @u.instance_variable_get(:@cache).should be_empty
    @u.instance_variable_get(:@nick_cache).should be_empty
  end

  it "should invalidate cache for a host" do
    @u.find(@host).should eq(@user)
    @u.instance_variable_get(:@cache).should include(@host)
    @u.invalidate_cache(@host)
    @u.instance_variable_get(:@cache).should be_empty
  end

  it "should be able to invalidate the cache for a server" do
    @u.find_by_nick(:gamesurge, 'aaron')
    @u.instance_variable_get(:@nick_cache).should include(:gamesurge)
    @u.invalidate_nick_cache(:gamesurge)
    @u.instance_variable_get(:@nick_cache).should_not include(:gamesurge)
  end

  it "should be able to invalidate the cache for a nickname" do
    @u.find_by_nick(:gamesurge, 'aaron')
    @u.instance_variable_get(:@nick_cache).should include(:gamesurge)
    @u.instance_variable_get(:@nick_cache)[:gamesurge].should include('aaron')
    @u.instance_variable_get(:@nick_cache)[:gamesurge]['aaron'].should eq(@user)
    @u.invalidate_nick_cache(:gamesurge, 'aaron')
    @u.instance_variable_get(:@nick_cache)[:gamesurge].should_not include('aaron')
  end

  it "should prepare to be serialized" do
    @user.add_server :gamesurge, false, 10
    @user[:gamesurge].set_state @host, 'Aaron L', ['#C++']
    @user[:gamesurge].nick.should_not be_nil
    @u.prepare_for_serialization
    @user[:gamesurge].access.should eq(10)
    @user[:gamesurge].nick.should be_nil
    @u.instance_variable_get(:@cache).should be_empty
  end

end

