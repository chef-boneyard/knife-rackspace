#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Copyright:: Copyright (c) 2008, 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'bundler/setup'
require 'jeweler'
require 'yard'


YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', 'LICENSE', 'README.md']
end

Jeweler::Tasks.new do |gem|
    require 'knife-rackspace/version'
    gem.name = "knife-rackspace"
    gem.version = Knife::Rackspace::VERSION
    gem.email = ["Adam Jacob","Seth Chisamore"]
    gem.authors = ["adam@opscode.com","schisamo@opscode.com"]
    gem.homepage = "http://wiki.opscode.com/display/chef"
    gem.summary = "Rackspace Support for Chef's Knife Command"
    gem.description = "This is the official Opscode Knife plugin for Rackspace. This plugin gives knife the ability to create, bootstrap, and manage servers on the Rackspace Cloud."
end