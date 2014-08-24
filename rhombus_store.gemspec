$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rhombus_store/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rhombus_store"
  s.version     = RhombusStore::VERSION
  s.authors     = ["Sumit Birla"]
  s.email       = ["sbirla@tampahost.net"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of RhombusStore."
  s.description = "TODO: Description of RhombusStore."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.1.4"

  s.add_dependency 'activemerchant'
  s.add_dependency 'barby'
  s.add_dependency 'chunky_png'
end
