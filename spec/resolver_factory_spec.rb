require_relative '../src/resolver_factory'

describe "ResolverFactory" do
  it "should resolve ip addresses to hostnames" do
    ResolverFactory.resolve('64.31.0.226').should match(/([a-z0-9]+\.)+[a-z]{2,}/i)
  end
end

