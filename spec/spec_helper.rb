require 'simplecov';
SimpleCov.add_filter('extensions')
SimpleCov.add_filter('spec')
SimpleCov.add_filter do |file|
  file.filename.match(/src\/.*_factory.rb/) != nil
end
SimpleCov.start

