require_relative '../src/resolver_factory.rb'

describe "ResolverFactory" do
  it "should resolve ip addresses to hostnames" do
    ResolverFactory.resolve '64.31.0.226'
  end
end
