require 'webmock/rspec'
require 'live_editor'

Dir["#{File.expand_path('../support', __FILE__)}/*.rb"].each do |file|
  require file
end
