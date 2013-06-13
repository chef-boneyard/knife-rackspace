require 'integration_spec_helper'
require 'chef/knife/rackspace_server_create'

[:v1, :v2].each do |api|
  describe api do
    before(:each) do
      Chef::Config[:knife][:rackspace_version] = api.to_s #v2 by default
    end

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
  end
end