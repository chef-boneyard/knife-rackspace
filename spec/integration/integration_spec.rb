require 'integration_spec_helper'
require 'fog'
require 'knife/dsl'
require 'chef/knife/rackspace_server_create'
# include Chef::Knife::DSL

api = :v2

describe api do
  before(:each) do
    Chef::Config[:knife][:rackspace_version] = api.to_s #v2 by default
    Chef::Config[:knife][:rackspace_region] = :iad

    Chef::Knife::Bootstrap.any_instance.stub(:run)
    Chef::Knife::RackspaceServerCreate.any_instance.stub(:tcp_test_ssh).with(anything).and_return(true)
  end

#   it 'should list server flavors', :vcr do
#     skip "Will hit this during refactoring"
#
#     stdout, stderr, status = knife_capture('rackspace flavor list')
#
#     expected_output = {
#       :v1 => """
# ID  Name           Architecture  RAM    Disk
# 1   256 server     64-bit        256    10 GB
# 2   512 server     64-bit        512    20 GB
# 3   1GB server     64-bit        1024   40 GB
# 4   2GB server     64-bit        2048   80 GB
# 5   4GB server     64-bit        4096   160 GB
# 6   8GB server     64-bit        8192   320 GB
# 7   15.5GB server  64-bit        15872  620 GB
# 8   30GB server    64-bit        30720  1200 GB
# """,
#       :v2 => """
# ID                Name                     VCPUs  RAM     Disk
# 2                 512MB Standard Instance  1      512     20 GB
# 3                 1GB Standard Instance    1      1024    40 GB
# 4                 2GB Standard Instance    2      2048    80 GB
# 5                 4GB Standard Instance    2      4096    160 GB
# 6                 8GB Standard Instance    4      8192    320 GB
# 7                 15GB Standard Instance   6      15360   620 GB
# 8                 30GB Standard Instance   8      30720   1200 GB
# performance1-1    1 GB Performance         1      1024    20 GB
# performance1-2    2 GB Performance         2      2048    40 GB
# performance1-4    4 GB Performance         4      4096    40 GB
# performance1-8    8 GB Performance         8      8192    40 GB
# performance2-120  120 GB Performance       32     122880  40 GB
# performance2-15   15 GB Performance        4      15360   40 GB
# performance2-30   30 GB Performance        8      30720   40 GB
# performance2-60   60 GB Performance        16     61440   40 GB
# performance2-90   90 GB Performance        24     92160   40 GB
# """}
#     stdout = ANSI.unansi stdout
#     stdout.should match_output(expected_output[api])
#   end

  it 'should list images', :vcr do
    sample_image = {
      :v1 => 'Ubuntu 12.04 LTS',
      :v2 => 'Ubuntu 12.04 LTS (Precise Pangolin)'
    }

    stdout, stderr, status = knife_capture('rackspace image list')
    status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"
    stdout = clean_output(stdout)
    stdout.should match /^ID\s*Name\s*$/
    stdout.should include sample_image[api]
  end

  # it 'should manage servers', :vcr do
  #   skip "The test works, but I'm in the process of cleaning up sensitive data in the cassettes"
  #
  #   image = {
  #     :v1 => '112',
  #     :v2 => 'e09ad6af-114d-40f7-8f70-652b61d1bbbc'
  #   }
  #
  #   flavor = 2
  #   server_list.should_not include 'test-node'
  #
  #   args = %W{rackspace server create -I #{image[api]} -f #{flavor} -N test-node -S test-server}
  #   stdout, stderr, status = knife_capture(args)
  #   status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"
  #   instance_data = capture_instance_data(stdout, {
  #     :name => 'Name',
  #     :instance_id => 'Instance ID',
  #     :public_ip => 'Public IP Address',
  #     :private_ip => 'Private IP Address'
  #   })
  #
  #   # Wanted to assert active state, but got build during test
  #   server_list.should match /#{instance_data[:instance_id]}\s*#{instance_data[:name]}\s*#{instance_data[:public_ip]}\s*#{instance_data[:private_ip]}\s*#{flavor}\s*#{image}/
  #
  #   args = %W{rackspace server delete #{instance_data[:instance_id]} -y}
  #   stdout, stderr, status = knife_capture(args)
  #   status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"
  #
  #   # Need to deal with deleting vs deleted states before we can check this
  #   # server_list.should_not match /#{instance_data[:instance_id]}\s*#{instance_data[:name]}\s*#{instance_data[:public_ip]}\s*#{instance_data[:private_ip]}\s*#{flavor}\s*#{image}/
  # end
end
