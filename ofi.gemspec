require File.expand_path('../lib/ofi/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'ofi'
  s.version     = Ofi::VERSION
  s.date        = Date.today.to_s
  s.authors     = ['OFI team']
  s.email       = ['foreman-dev+ofi@googlegroups.com']
  s.homepage    = 'https://github.com/theforeman/OFI'
  s.summary     = 'OpenStack Foreman Installer'
  s.description = 'OpenStack Foreman Installer'

  s.files = Dir['{app,config,db,lib}/**/*'] + %w(LICENSE Rakefile README.md)
  s.test_files = Dir['test/**/*']

  s.add_dependency 'foreman-tasks'

end
