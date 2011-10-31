require_relative '../src/bot'
require_relative '../src/bot_instance'

describe "Bot" do
  def init_config
    config = YAML::load(
      ":nick: infinityq\n" +
      ":altnick: infinityqq\n" +
      ":name: Infinity Ruby Bot\n" +
      ":email: inf_bot@gmail.com\n" +
      ":proto: irc.proto\n" +
      ":extpath: .\n" +
      ":extprefix: .\n" +
      ":extensions:\n" +
      "  -Test1\n" +
      ":extensioncfg:\n" +
      "  Test1:\n" +
      "    :test: :load\n" +
      ":servers:\n" +
      "  :gamesurge:\n" +
      "    :address: irc.gamesurge.net\n" +
      "    :port: 6667\n" +
      "    :nick: infinity_\n" +
      "    :altnick: infinity__\n"
    )

    Bot::Config.clear
    config.each do |k, v|
      Bot::Config[k] = v
    end
  end

  before :each do
    if ENV["INF_ENV"] == 'TEST'
      init_config
    else
      Bot::read_config
    end

    @userio = double('IO')
    @chanio = double('IO')
    @userstore = nil
    @chanstore = nil
    @userio.stub(:write) do |arg|; @userstore = arg; end
    @chanio.stub(:write) do |arg|; @chanstore = arg; end
    @userio.stub(:read) do |arg|; @userstore; end
    @chanio.stub(:read) do |arg|; @chanstore; end

    if ENV['INF_ENV'] == "TEST"
      Bot::read_databases(@userstore ? @userio : nil, @chanstore ? @chanio : nil)
    else
      Bot::prep_db_read do |u, c|
        Bot::read_databases(u, c)
      end
    end
  end

  it "should create a server object for each server in the config" do
    Bot::start
    Bot::Config[:servers].each_key do |k|
      Bot::instance(k).should be_kind_of(BotInstance)
    end
  end

  it "should iterate through all the servers" do
    Bot::start
    Bot::each do |i|
      i.should be_kind_of(BotInstance)
      Bot::Config[:servers].should include(i.key)
    end
  end

  it "should wait until all other threads exit" do
    Bot::start
    Bot::each do |i|
      i.halt
    end
    Bot::wait_until_death
  end

  it "should have a user and channel database" do
    Bot::userdb.should_not be_nil
    Bot::chandb.should_not be_nil
  end

  it "should save databases and reload them from a file" do
    u = User.new()
    u.add_server(:gamesurge)
    u[:gamesurge].set_state('~Aaron@bitforge.ca')
    Bot::userdb.add(u)
    u = User.new(false)
    u.add_host(/.*@bettercoder\.net/i)
    Bot::userdb.add(u)

    if ENV['INF_ENV'] == "TEST"
      Bot::save_databases(@userio, @chanio)
      Bot::read_databases(@userio, @chanio)
    else
      Bot::prep_db_write do |u, c|
        Bot::save_databases(u, c)
      end
      Bot::prep_db_read do |u, c|
        Bot::read_databases(u, c)
      end
    end

    Bot::userdb.find('~fish@bettercoder.net').should be_a(User)
    Bot::userdb.find('Aaron@bitforge.ca').should be_nil
  end
end

