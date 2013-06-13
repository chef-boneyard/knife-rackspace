$:.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
SimpleCov.start
require 'chef/knife/bootstrap'
require 'chef/knife/rackspace_base'
