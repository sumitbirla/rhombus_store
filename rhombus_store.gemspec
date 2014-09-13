$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rhombus_store/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "rhombus_store"
  s.version     = RhombusStore::VERSION
  s.authors     = ["Sumit Birla"]
  s.email       = ["sbirla@tampahost.net"]
  s.homepage    = "http://github.com/sumitbirla/rhombus_store"
  s.summary     = "eCommerce plugin for Rhombus"
  s.description = "Rhombus is a rails framework to quickly spin up website with different sets of functionality."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 4.1.4"

  s.add_dependency 'activemerchant'
  s.add_dependency 'barby'
  s.add_dependency 'chunky_png'
end
