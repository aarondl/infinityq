require_relative '../src/file_factory'

describe "FileFactory" do

  it "creates new files" do #new and exists!
    old = ENV['INF_ENV']
    ENV['INF_ENV'] = 'TEST'
    temp = FileFactory.create(__FILE__, "r")
    temp.should be_instance_of(RSpec::Mocks::Mock)
    ENV['INF_ENV'] = ''
    temp = FileFactory.create(__FILE__, "r")
    temp.should be_instance_of(File)
    ENV['INF_ENV'] = old
    temp.close
  end

  it "confirms existing files" do  
    old = ENV['INF_ENV']
    ENV['INF_ENV'] = 'TEST'
    FileFactory.exists?(__FILE__).should be_true
    ENV['INF_ENV'] = ''
    FileFactory.exists?(__FILE__).should be_true
    ENV['INF_ENV'] = old
  end

  it "confirms non-existing files" do
    old = ENV['INF_ENV']
    ENV['INF_ENV'] = ''
    FileFactory.exists?("").should be_false
    ENV['INF_ENV'] = 'TEST'
    FileFactory.exists?("").should be_true
    ENV['INF_ENV'] = old
  end

end

