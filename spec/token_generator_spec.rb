require_relative '../src/token_generator'

describe "TokenGenerator" do
  it "should generate good tokens" do
    TokenGenerator::generate_token.to_s.should match(/^[a-z][a-z0-9]{16,32}$/)
  end  
end

