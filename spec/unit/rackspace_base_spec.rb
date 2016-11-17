require "spec_helper"

require "chef/knife/rackspace_base"
require "chef/knife"

class RackspaceBaseTester < Chef::Knife
  include Chef::Knife::RackspaceBase
end

describe "auth_endpoint" do
  it "should select the custom endpoint if specified" do
    tester = RackspaceBaseTester.new

    test_url = "http://test-url.com"
    Chef::Config[:knife][:rackspace_auth_url] = test_url
    Chef::Config[:knife][:rackspace_region] = :ord

    expect(tester.auth_endpoint).to eq(test_url)
  end

  [:dfw, :ord, :syd].each do |region|
    it "should pick the US endpoint if the region is #{region}" do
      tester = RackspaceBaseTester.new
      Chef::Config[:knife][:rackspace_auth_url] = nil
      Chef::Config[:knife][:rackspace_region] = region

      expect(tester.auth_endpoint).to eq(::Fog::Rackspace::US_AUTH_ENDPOINT)
    end
  end

  it "should pick the UK end point if the region is :lon" do
    tester = RackspaceBaseTester.new
    Chef::Config[:knife][:rackspace_auth_url] = nil
    Chef::Config[:knife][:rackspace_region] = "lon"

    expect(tester.auth_endpoint).to eq(::Fog::Rackspace::UK_AUTH_ENDPOINT)
  end
end

describe "locate_config_value" do
  it 'with cli options' do
    # CLI
    tester = RackspaceBaseTester.new
    tester.parse_options([ "--rackspace-api-key", "12345" ])

    # Knife Config
    Chef::Config[:knife][:rackspace_api_key] = "67890"

    # Test
    expect(tester.locate_config_value(:rackspace_api_key)).to eq("12345")
  end

  it 'without cli options' do
    # CLI
    tester = RackspaceBaseTester.new
    tester.parse_options([])

    # Knife Config
    Chef::Config[:knife][:rackspace_api_key] = "67890"

    # Test
    expect(tester.locate_config_value(:rackspace_api_key)).to eq("67890")
  end
end
