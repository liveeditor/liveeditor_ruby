lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'live_editor/version'

Gem::Specification.new do |gem|
  gem.name          = 'liveeditor_api'
  gem.version       = LiveEditor::VERSION
  gem.authors       = ['Chris Peters']
  gem.email         = ['webmaster@liveeditorcms.com']
  gem.description   = 'Ruby SDK for interacting with the Live Editor JSON APIs.'
  gem.summary       = "Connect to Live Editor's authentication, content management system, and content delivery network APIs."
  gem.homepage      = 'http://liveeditorcms.com/docs/developers/'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ['lib']

  gem.add_dependency 'net_http_ssl_fix'

  gem.add_development_dependency 'rspec',   '~> 3.5.0'
  gem.add_development_dependency 'webmock', '~> 2.3.2'
end
