# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-rackspace/version"

Gem::Specification.new do |s|
  s.name        = "knife-rackspace"
  s.version     = Knife::Rackspace::VERSION
  s.authors     = ["Adam Jacob", "Seth Chisamore", "Matt Ray", "Rackspace Developers", "JJ Asghar"]
  s.email       = ["adam@chef.io", "schisamo@chef.io", "matt@chef.io", "jj@chef.io"]
  s.homepage    = "https://github.com/chef/knife-rackspace"
  s.summary     = "Rackspace Support for Chef's Knife Command"
  s.description = s.summary
  s.license     = "Apache-2.0"

  s.required_ruby_version = ">= 2.3"
  s.files         = %w(LICENSE) + Dir.glob("lib/**/*")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.add_dependency "knife-windows"
  s.add_dependency "fog-rackspace", ">= 0.1"
  s.add_dependency "chef", ">= 13.0"
  s.require_paths = ["lib"]
end
