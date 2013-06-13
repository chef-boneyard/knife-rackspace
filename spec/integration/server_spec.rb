require 'integration_spec_helper'
require 'chef/knife/rackspace_server_create'

[:v1, :v2].each do |api|
  describe api do
    before(:each) do
      Chef::Config[:knife][:rackspace_version] = api.to_s #v2 by default

      Chef::Knife::Bootstrap.any_instance.stub(:run)
      Chef::Knife::RackspaceServerCreate.any_instance.stub(:tcp_test_ssh).with(anything).and_return(true)
    end

    it 'should manage servers', :vcr do
      pending "The test works, but I'm in the process of cleaning up sensitive data in the cassettes" unless ENV['INTEGRATION_TESTS'] == 'live'

      image = {
        :v1 => '112',
        :v2 => 'e4dbdba7-b2a4-4ee5-8e8f-4595b6d694ce'
      }
      flavor = 2
      node_name = "knife-rackspace-#{api.to_s}-test-node"
      server_list.should_not include node_name

      args = %W{rackspace server create -I #{image[api]} -f #{flavor} -N #{node_name} -S test-server}
      stdout, stderr, status = knife_capture(args)
      status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"
      instance_data = capture_instance_data(stdout, {
        :name => 'Name',
        :instance_id => 'Instance ID',
        :public_ip => 'Public IP Address',
        :private_ip => 'Private IP Address'
      })

      # Wanted to assert active state, but got build during test
      server_list.should match /#{instance_data[:instance_id]}\s*#{instance_data[:name]}\s*#{instance_data[:public_ip]}\s*#{instance_data[:private_ip]}\s*#{flavor}\s*#{image[api]}/

      args = %W{rackspace server delete #{instance_data[:instance_id]} -y}
      stdout, stderr, status = knife_capture(args)
      status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"

      # Need to deal with deleting vs deleted states before we can check this
      # server_list.should_not match /#{instance_data[:instance_id]}\s*#{instance_data[:name]}\s*#{instance_data[:public_ip]}\s*#{instance_data[:private_ip]}\s*#{flavor}\s*#{image}/
    end
  end
end