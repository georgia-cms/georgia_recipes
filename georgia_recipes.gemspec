# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'georgia_recipes/version'

Gem::Specification.new do |spec|
  spec.name          = "georgia_recipes"
  spec.version       = GeorgiaRecipes::VERSION
  spec.authors       = ["Mathieu Gagne"]
  spec.email         = ["gagne.mathieu@hotmail.com"]
  spec.description   = %q{Capistrano recipes for Georgia CMS.}
  spec.summary       = %q{Capistrano recipes for Georgia CMS. Helps you setup a VM with the necessary dependencies to run a full Rails stack with Georgia CMS}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano", '~> 2'
  spec.add_dependency "capistrano-ext"
  spec.add_dependency "capistrano-maintenance"
end
