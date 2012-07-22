# FileFactory, gets a real File or a mock
# depending on environment.
class FileFactory
  # Creates a file handler / mock depending on the env variable.
  #
  # @param [Array] Path and permission arguments.
  # @return [File] New File Object.
  def self.create(*args)
    if ENV['INF_ENV'] != 'TEST'
      return File.new(*args)
    else
      require "rspec/mocks/standalone"
      RSpec::Mocks::setup(self)
      return double("File", :close => nil, :closed? => true, :read => @@data)
    end
  end

  # Preloads the mock file with data
  #
  # @param [String] The data to return in read.
  # @return [nil] Nil
  def self.preload(data)
    @@data = data
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

