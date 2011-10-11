require_relative '../src/stdout_provider'

describe "StdoutProvider" do
  it "should provide access to a write method" do
      p = StdoutProvider.new()
      p.respond_to?(:write).should be_true
      p.method(:write).arity.should eq(2)
  end
end
