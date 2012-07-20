require_relative '../src/file_factory'

describe "FileFactory" do

  it "creates new files" do #new and exists!
    temp = FileFactory.create(__FILE__, "r")
    if ENV['INF_ENV'] == 'TEST'
      temp.should be_instance_of(RSpec::Mocks::Mock)
    else
      temp.should be_instance_of(File)
    end
    temp.close
  end

  it "confirms existing files" do  
    FileFactory.exists?(__FILE__).should be_true
  end

end

