require 'integration_spec_helper'
require 'chef/knife/rackspace_server_create'

describe :v1 do
  before(:each) do
    Chef::Config[:knife][:rackspace_version] = 'v1'
  end

  it 'should not support networks', :vcr do
    stdout, stderr, status = knife_capture('rackspace network list')
    # Having trouble capturing stderr with knife-dsl
    # stdout.should match 'Networks are not supported in v1'
    status.should eq 1
  end
end

describe :v2 do
  before(:each) do
    Chef::Config[:knife][:rackspace_version] = 'v2'
  end  

  it 'should list networks', :vcr do
    stdout, stderr, status = knife_capture('rackspace network list')
    status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"

    stdout = clean_output(stdout)
    stdout.should match /^Label\s*CIDR\s*ID$/
    stdout.should match /^private\s*11111111-1111-1111-1111-111111111111/
  end

  it 'should manage networks', :vcr do
    args = %W{rackspace network create -L test-network -C 10.0.0.0/24}
    stdout, stderr, status = knife_capture(args)
    status.should eq 0

    network_data = capture_instance_data(stdout, {
        :network_id => 'Network ID',
        :label => 'Label',
        :cidr => 'CIDR'
      })
    VCR.configuration.filter_sensitive_data(network_data[:network_id], '_NETWORK_ID')
    network_data[:label].should eq('test-network')
    args = %W{rackspace network delete #{network_data[:network_id]} -y}
    stdout, stderr, status = knife_capture(args)
    status.should eq 0
  end
end