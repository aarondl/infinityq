require_relative '../src/log'

describe "Log" do
  it "should provide logging with various levels" do
    provider = double('StdoutProvider')
    provider.should_receive(:write).with('Warning: hello', Log::Warning).ordered
    provider.should_receive(:write).with('Error: there', Log::Error).ordered
    provider.should_receive(:write).with('sir', Log::Information).ordered
    Log::set_provider provider
    Log::write 'hello', Log::Warning
    Log::write 'there', Log::Error
    Log::write 'sir'
  end

  it "should throw errors if no provider is set" do
    Log::set_provider nil
    expect {
      Log::write 'hello'
    }.to raise_error(StandardError)
  end
end

