# FileFactory, gets a real File or a mock
# depending on environment.
class FileFactory
  # Creates a file handler / mock depending on the env variable.
  #
  # @param [String] The path to the file being created.
  # @param [String] The mode the File object will be in.
  # @return [File] New File Object.
  def self.create(path, perm = nil)
    if ENV['INF_ENV'] != 'TEST'
      unless perm.nil?
        return File.new(path, perm)
       end
    else
      require "rspec/mocks/standalone"
      RSpec::Mocks::setup(self)
      return double("File", :class => "File")
    end
  end

  # Checks whether file exists depending on env variable.
  #
  # @param [String] The path to the file being checked.
  # @return [Boolean] Whether file exists or not.
  def self.exists?(path)
    if ENV['INF_ENV'] != 'TEST'
      return File.exists?(path)
    else
      return true
    end
  end

end

