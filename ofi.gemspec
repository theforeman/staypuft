require File.expand_path('../lib/ofi/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "ofi"
  s.version     = Ofi::VERSION
  s.date        = Date.today.to_s
  s.authors     = ["TODO: Your name"]
  s.email       = ["TODO: Your email"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Ofi."
  s.description = "TODO: Description of Ofi."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

end
