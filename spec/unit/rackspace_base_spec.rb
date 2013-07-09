require 'spec_helper'

require 'chef/knife/rackspace_base'
require 'chef/knife'

class RackspaceBaseTester < Chef::Knife
  include Chef::Knife::RackspaceBase
end

describe "auth_endpoint" do
  it "should select the custom endpoint if specified" do
    tester = RackspaceBaseTester.new

    test_url = "http://test-url.com"
    Chef::Config[:knife][:rackspace_auth_url] = test_url
    Chef::Config[:knife][:rackspace_region] = :ord

    tester.auth_endpoint.should == test_url
  end

  [:dfw, :ord, :syd].each do |region|
    it "should pick the US endpoint if the region is #{region}" do
      tester = RackspaceBaseTester.new
      Chef::Config[:knife][:rackspace_auth_url] = nil
      Chef::Config[:knife][:rackspace_region] = region

      tester.auth_endpoint.should == ::Fog::Rackspace::US_AUTH_ENDPOINT
    end
  end

  it "should pick the UK end point if the region is :lon" do
    tester = RackspaceBaseTester.new
    Chef::Config[:knife][:rackspace_auth_url] = nil
    Chef::Config[:knife][:rackspace_region] = 'lon'

    tester.auth_endpoint.should == ::Fog::Rackspace::UK_AUTH_ENDPOINT
  end
end