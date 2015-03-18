$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef/knife/bootstrap'
require 'chef/knife/rackspace_base'

if RUBY_VERSION < '2.0'
  require 'debugger'
else
  require 'byebug'
end

RSpec.configure do |config|
  config.color = true
end

