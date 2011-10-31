require_relative '../../src/user/user_db'
require_relative '../../src/user/user'

describe "UserDb" do
  before :each do
    @u = UserDb.new()

    @user = User.new(false)
    @user.add_host(/.*@bitforge\.ca$/)
    @user.global_access.power = 10
    @user.global_access[Access::A]

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
    @u.remove_host('~aaron@bitforge.ca')
    @u.users.should_not include(@user)
  end

  it "should be able to find a user based on host" do
    @u.find('~aaron@bitforge.ca').should eq(@user)
    @u.find('lol').should be_nil
  end

  it "should cache lookups" do
    @u.find('~aaron@bitforge.ca').should eq(@user)
    @u.instance_variable_get(:@cache).should include('~aaron@bitforge.ca')
    @u.instance_variable_get(:@cache)['~aaron@bitforge.ca'].should eq(@user)
  end

  it "should be able to flush the cache" do
    @u.find('~aaron@bitforge.ca').should eq(@user)
    @u.flush_cache
    @u.instance_variable_get(:@cache).should be_empty
  end

  it "should invalidate cache for a host" do
    @u.find('~aaron@bitforge.ca').should eq(@user)
    @u.instance_variable_get(:@cache).should include('~aaron@bitforge.ca')
    @u.invalidate_cache('~aaron@bitforge.ca')
    @u.instance_variable_get(:@cache).should be_empty
  end

  it "should prepare to be serialized" do
    @user.add_server :gamesurge, false, 10
    @user[:gamesurge].set_state '~aaron@bitforge.ca', 'Aaron L', ['#C++']
    @user[:gamesurge].nick.should_not be_nil
    @u.prepare_for_serialization
    @user[:gamesurge].access.should eq(10)
    @user[:gamesurge].nick.should be_nil
    @u.instance_variable_get(:@cache).should be_empty
  end

end

