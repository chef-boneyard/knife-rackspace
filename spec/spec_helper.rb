$:.unshift File.expand_path('../../lib', __FILE__)
require 'chef/knife/bootstrap'
require 'chef/knife/rackspace_base'

TESTING = true

if RUBY_VERSION < '2.0'
  require 'debugger'
else
  require 'byebug'
end

RSpec.configure do |config|
  config.color = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed

  config.before(:example) do
    # reset any Chef::Config vars so we don't get test order dependencies
    Chef::Config[:knife] = {}
  end
end

