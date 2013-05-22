require 'integration_spec_helper'
require 'fog'
require 'knife/dsl'

include Chef::Knife::DSL

describe 'v2_api' do
  before do
    Chef::Config[:knife][:rackspace_version] = nil #v2 by default
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
end
