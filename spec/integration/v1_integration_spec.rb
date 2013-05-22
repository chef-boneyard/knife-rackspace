require 'integration_spec_helper'
require 'fog'
require 'knife/dsl'

include Chef::Knife::DSL

describe 'v1_api' do
  before do
    Chef::Config[:knife][:rackspace_version] = 'v1'
  end

  it 'should list server flavors', :vcr do
    stdout, stderr, status = knife_capture('rackspace flavor list')
    status.should == 0
    stdout.should match_output("""
ID  Name           Architecture  RAM    Disk
1   256 server     64-bit        256    10 GB
2   512 server     64-bit        512    20 GB
3   1GB server     64-bit        1024   40 GB
4   2GB server     64-bit        2048   80 GB
5   4GB server     64-bit        4096   160 GB
6   8GB server     64-bit        8192   320 GB
7   15.5GB server  64-bit        15872  620 GB
8   30GB server    64-bit        30720  1200 GB
""")
  end
end
