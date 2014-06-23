require File.expand_path('../lib/staypuft/version', __FILE__)
require 'date'

Gem::Specification.new do |s|
  s.name        = 'staypuft'
  s.version     = Staypuft::VERSION
  s.date        = Date.today.to_s
  s.authors     = ['Staypuft team']
  s.email       = ['foreman-dev+staypuft@googlegroups.com']
  s.homepage    = 'https://github.com/theforeman/staypuft'
  s.summary     = 'OpenStack Foreman Installer'
  s.description = 'OpenStack Foreman Installer'

  s.files      = (Dir['{app,config,db,lib, doc}/**/*'] + %w(LICENSE Rakefile README.md)) &
      `git ls-files`.split
  s.test_files = Dir['test/**/*']

  s.add_dependency 'foreman-tasks', '~> 0.6.4'
  s.add_dependency 'dynflow', '~> 0.7.0'
  s.add_dependency 'wicked'

  s.add_dependency 'foreman_discovery', '~> 1.3.0.rc1'
end
