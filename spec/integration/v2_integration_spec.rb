require 'integration_spec_helper'
require 'fog'
require 'knife/dsl'
require 'chef/knife/rackspace_server_create'
include Chef::Knife::DSL

describe 'v2_api' do
  def server_list
    stdout, stderr, status = knife_capture('rackspace server list')
    status == 0 ? stdout : stderr
  end

  before(:each) do
    Chef::Config[:knife][:rackspace_version] = nil #v2 by default

    Chef::Knife::Bootstrap.any_instance.stub(:run)
    Chef::Knife::RackspaceServerCreate.any_instance.stub(:tcp_test_ssh).with(anything).and_return(true)
  end

  it 'should list server flavors', :vcr do
    stdout, stderr, status = knife_capture('rackspace flavor list')
    status.should == 0
    stdout.should match_output("""
ID  Name                     VCPUs  RAM    Disk
2   512MB Standard Instance  1      512    20 GB
3   1GB Standard Instance    1      1024   40 GB
4   2GB Standard Instance    2      2048   80 GB
5   4GB Standard Instance    2      4096   160 GB
6   8GB Standard Instance    4      8192   320 GB
7   15GB Standard Instance   6      15360  620 GB
8   30GB Standard Instance   8      30720  1200 GB
""")
  end

  it 'should list images', :vcr do
    stdout, stderr, status = knife_capture('rackspace image list')
    status.should == 0
    stdout = ANSI.unansi stdout
    stdout.should match /^ID\s*Name\s*$/
    stdout.should include 'Ubuntu 12.10 (Quantal Quetzal)'
  end

  it 'should manage servers', :vcr do
    # image = '112' # v1
    image = '9922a7c7-5a42-4a56-bc6a-93f857ae2346'
    # Faster? flavor 4, image 88130782-11ec-4795-b85f-b55a297ba446
    flavor = '2'
    role = 'role[dummy_server_for_integration_test]'
    server_list.should_not include 'test-node'

    args = %W{rackspace server create -I #{image} -f #{flavor} -r 'role[webserver]' -N test-node -S test-server}
    stdout, stderr, status = knife_capture(args)
    status.should == 0
    instance_data = capture_instance_data(stdout, {
      :name => 'Name',
      :instance_id => 'Instance ID',
      :public_ip => 'Public IP Address',
      :private_ip => 'Private IP Address'
    })

    # Wanted to assert active state, but got build during test
    server_list.should match /#{instance_data[:instance_id]}\s*#{instance_data[:name]}\s*#{instance_data[:public_ip]}\s*#{instance_data[:private_ip]}\s*#{flavor}\s*#{image}/

    args = %W{rackspace server delete #{instance_data[:instance_id]} -y}
    stdout, stderr, status = knife_capture(args)
    status.should == 0

    # Need to deal with deleting vs deleted states before we can check this
    # server_list.should_not match /#{instance_data[:instance_id]}\s*#{instance_data[:name]}\s*#{instance_data[:public_ip]}\s*#{instance_data[:private_ip]}\s*#{flavor}\s*#{image}/
  end

  def capture_instance_data(stdout, labels = {})
    result = {}
    labels.each do | key, label |
      result[key] = clean_output(stdout).match(/^#{label}: (.*)$/)[1]
    end
    result
  end

end
