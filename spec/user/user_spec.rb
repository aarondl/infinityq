require_relative '../../src/user/user'

describe "User" do
  before :each do
    @host = '*@b?tforge.ca'
    @u = User.new
    @u.add_host(@host)
  end

  it "should keep a list of hosts" do
    @u.add_host(@host)
    @u.each_host do |h|
      h.should eq(@host)
    end
    @u.hosts_count.should eq(1)
  end

  it "should keep global access" do
    @u.global_access.power.should be_zero
  end

  context "when it has some server access for :gamesurge" do
    before :each do
      @u.add_server(:gamesurge, 50, Access::A)
    end

    context "and it has channel access for #C++" do
      before :each do
        @u[:gamesurge].add_channel('#C++', 100, Access::C)
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
  end

end

