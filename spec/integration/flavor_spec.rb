require 'integration_spec_helper'
require 'chef/knife/rackspace_server_create'

[:v1, :v2].each do |api|
  describe api do
    before(:each) do
      Chef::Config[:knife][:rackspace_version] = api.to_s #v2 by default
    end

    it 'should list flavors', :vcr do
      stdout, stderr, status = knife_capture('rackspace flavor list')
      status.should be(0), "Non-zero exit code.\n#{stdout}\n#{stderr}"

      expected_output = {
        :v1 => """
ID  Name           Architecture  RAM    Disk
1   256 server     64-bit        256    10 GB
2   512 server     64-bit        512    20 GB
3   1GB server     64-bit        1024   40 GB
4   2GB server     64-bit        2048   80 GB
5   4GB server     64-bit        4096   160 GB
6   8GB server     64-bit        8192   320 GB
7   15.5GB server  64-bit        15872  620 GB
8   30GB server    64-bit        30720  1200 GB
""",
        :v2 => """
ID  Name                     VCPUs  RAM    Disk
2   512MB Standard Instance  1      512    20 GB
3   1GB Standard Instance    1      1024   40 GB
4   2GB Standard Instance    2      2048   80 GB
5   4GB Standard Instance    2      4096   160 GB
6   8GB Standard Instance    4      8192   320 GB
7   15GB Standard Instance   6      15360  620 GB
8   30GB Standard Instance   8      30720  1200 GB
  """}
      stdout = ANSI.unansi stdout
      stdout.should match_output(expected_output[api])
    end
  end
end