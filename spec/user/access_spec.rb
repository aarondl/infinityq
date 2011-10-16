require_relative '../../src/user/access'

describe "Access" do
  before :each do
    @a = Access.new()
  end

  it "should be constructed with optional access vars" do
    @a = Access.new(10, Access::A, Access::B)
    @a.power.should eq(10)
    @a.has?(Access::A, Access::B).should be_true
  end

  it "should provide a numerical access" do
    @a.power.should be_zero
    @a.power = 10
    @a.power.should eq(10)
  end

  it "should preserve flags when setting power" do
    @a.add(Access::A)
    @a.power = 10
    @a.has?(Access::A).should be_true
  end

  it "should convert string flags to real flags" do
    @a.add('a')
    @a.has?('a').should be_true
  end

  it "should check for flags" do
    @a.add(Access::A)
    @a.has?(Access::A).should be_true
    @a.has?(Access::B).should be_false
  end

  it "should allow multiple flag adds and verifies" do
    @a.add(Access::A, Access::C)
    @a.has?(Access::A, Access::C).should be_true
    @a.has?(Access::B, Access::C).should be_false
  end

  it "should allow 'or' verification of flags" do
    @a.add(Access::C)
    @a.has_any?(Access::A, Access::C).should be_true
    @a.has_any?(Access::A).should be_false
  end

  it "should provide powers between 0 and 100 only" do
    expect {
      @a.power = 101
    }.to raise_error(ArgumentError)
    expect {
      @a.power = -1
    }.to raise_error(ArgumentError)
  end

  it "should provide shortcuts to verify power" do
    @a.power = 60
    (@a > 59).should be_true
    (@a < 61).should be_true
    (@a > 70).should be_false
    (@a == 40).should be_false
    (@a == 60).should be_true
    (@a != 40).should be_true
    (@a != 60).should be_false
  end

  it "should provide shortcuts to check for flags" do
    @a.add(Access::A, Access::B)
    @a[Access::A, Access::B].should be_true
  end

  it "should serialize nicely" do
    require 'yaml'
    @a = Access.new(50, Access::A, Access::B)
    @a = YAML::load(YAML::dump(@a))
    @a.power.should eq(50)
    @a.has?(Access::A, Access::B).should be_true
  end

  it "should be able to merged with priority" do
    a = Access.new(20, Access::A)
    b = Access.new(50, Access::B)
    c = Access.new(40, Access::C, Access::D)
    d = Access::merge(a, b, c)
    d.power.should eq(50)
    d.has?(Access::A, Access::B, Access::C, Access::D).should be_true
    e = Access::merge(c, b)
    e.power.should eq(50)
    d.has?(Access::B, Access::C, Access::D).should be_true
  end
end

