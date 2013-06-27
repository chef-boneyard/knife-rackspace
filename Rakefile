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

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
# RSpec::Core::RakeTask.new(:spec)
RSpec::Core::RakeTask.new(:spec, :example) do |t, task_args|
  t.rspec_opts = "-e '#{task_args[:example]}'"
end

task :default => [:credentials, :spec, 'integration:live']

task :credentials do
  if ENV['TRAVIS_SECURE_ENV_VARS'] == 'false'
    puts "Setting vars"
    ENV['OS_USERNAME'] = '_RAX_USERNAME_'
    ENV['OS_PASSWORD'] = '_RAX_PASSWORD_'
  end
  ENV['RS_TENANT_ID'] ||= '000000'
  ENV['RS_CDN_TENANT_NAME'] ||= '_CDN-TENANT-NAME_'
  fail "Not all required variables detected" unless ENV['OS_USERNAME'] && ENV['OS_PASSWORD'] && ENV['RS_CDN_TENANT_NAME'] && ENV['RS_TENANT_ID']
end

namespace :integration do
  desc 'Run the integration tests'
  RSpec::Core::RakeTask.new(:test, :example) do |t, task_args|
    t.pattern = 'spec/integration/**'
    t.rspec_opts = "-e '#{task_args[:example]}'"
  end

  desc 'Run the integration tests live (no VCR cassettes)'
  task :live do
    unless ENV['TRAVIS'] == 'true' && ENV['TRAVIS_SECURE_ENV_VARS'] == 'false'
      ENV['INTEGRATION_TESTS'] = 'live'
      Rake::Task['integration:test'].invoke
    end
  end
end
