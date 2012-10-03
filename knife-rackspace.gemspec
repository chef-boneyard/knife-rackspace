# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "knife-rackspace/version"

Gem::Specification.new do |s|
  s.name        = "knife-rackspace"
  s.version     = Knife::Rackspace::VERSION
  s.has_rdoc = true
  s.authors     = ["Adam Jacob","Seth Chisamore", "Matt Ray"]
  s.email       = ["adam@opscode.com","schisamo@opscode.com", "matt@opscode.com"]
  s.homepage = "http://wiki.opscode.com/display/chef"
  s.summary = "Rackspace Support for Chef's Knife Command"
  s.description = s.summary
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency "fog", "~> 1.6"
  s.add_dependency "chef", ">= 0.10.10"
  s.require_paths = ["lib"]

end
