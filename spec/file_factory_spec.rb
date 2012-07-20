require_relative '../src/file_factory'

describe "FileFactory" do

  it "creates new files" do #new and exists!
    temp = FileFactory.create(__FILE__, "r")
    temp.kind_of?(File)
    temp.close
  end

  it "confirms existing files" do  
    FileFactory.exists?(__FILE__).should be_true
  end

end

