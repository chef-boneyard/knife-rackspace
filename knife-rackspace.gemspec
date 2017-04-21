# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-rackspace/version"

Gem::Specification.new do |s|
  s.name        = "knife-rackspace"
  s.version     = Knife::Rackspace::VERSION
  s.has_rdoc = true
  s.authors     = ["Adam Jacob", "Seth Chisamore", "Matt Ray", "Rackspace Developers", "JJ Asghar"]
  s.email       = ["adam@chef.io", "schisamo@chef.io", "matt@chef.io", "jj@chef.io"]
  s.homepage = "https://github.com/chef/knife-rackspace"
  s.summary = "Rackspace Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.md", "LICENSE" ]

  s.required_ruby_version = ">= 2.2.2"
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.add_dependency "knife-windows"
  s.add_dependency "fog-rackspace", ">= 0.1.5"
  s.add_dependency "chef", ">= 12.0"
  s.require_paths = ["lib"]
end
