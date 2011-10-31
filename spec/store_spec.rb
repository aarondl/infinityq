require_relative '../src/store'

describe "Store" do
  it "should store key value pairs" do
    s = Store.new()
    s.fetch(:key).should be_nil
    s.store(:key, :value)
    s.fetch(:key).should eq(:value)
    s[:key] = :other
    s[:key].should eq(:other)
  end
end

