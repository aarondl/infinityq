require_relative '../src/file_factory'

describe "FileFactory" do
  it "should preload and read test data" do
    FileFactory::preload('test')
    old = ENV['INF_ENV']
    ENV['INF_ENV'] = 'TEST'
    file = FileFactory::create(__FILE__)
    file.read.should eq('test')
    file.close
    ENV['INF_ENV'] = ''
    file = FileFactory::create(__FILE__)
    file.read.should_not eq('test')
    file.close
    ENV['INF_ENV'] = old
  end

  it "creates new files" do
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

