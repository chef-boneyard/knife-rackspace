require 'spec_helper'

require 'chef/knife/rackspace_base'
require 'chef/knife'

class RackspaceBaseTester < Chef::Knife
  include Chef::Knife::RackspaceBase
end

describe Chef::Knife::RackspaceBase do
  let(:tester) { RackspaceBaseTester.new }

  describe "auth_endpoint" do
    it "should select the custom endpoint if specified" do
      test_url = "http://test-url.com"
      Chef::Config[:knife][:rackspace_auth_url] = test_url
      Chef::Config[:knife][:rackspace_region] = :ord

      expect(tester.auth_endpoint).to eq(test_url)
    end

    [:dfw, :ord, :syd].each do |region|
      it "should pick the US endpoint if the region is #{region}" do
        Chef::Config[:knife][:rackspace_auth_url] = nil
        Chef::Config[:knife][:rackspace_region] = region

        expect(tester.auth_endpoint).to eq(::Fog::Rackspace::US_AUTH_ENDPOINT)
      end
    end

    it "should pick the UK end point if the region is :lon" do
      Chef::Config[:knife][:rackspace_auth_url] = nil
      Chef::Config[:knife][:rackspace_region] = 'lon'

      expect(tester.auth_endpoint).to eq(::Fog::Rackspace::UK_AUTH_ENDPOINT)
    end
  end

  describe '#connection' do
    let(:ui) { double(Chef::Knife::UI) }

    before do
      allow(Chef::Knife::UI).to receive(:new).and_return(ui)
    end

    it 'raises a ui error and exits unless rackspace region has been set' do
      expect(ui).to receive(:error).with(/Please specify region/)

      Chef::Config[:knife][:rackspace_region] = nil

      expect{ tester.connection }.to raise_error(SystemExit)
    end
  end

  describe '#block_storage_connection' do
    let(:fog_connection) { double(Fog::Rackspace::BlockStorage) }

    it 'returns a Fog block storage connection initialized with block storage connection params' do
      expect(Fog::Rackspace::BlockStorage).to receive(:new).and_return(fog_connection)

      expect(tester.block_storage_connection).to eq(fog_connection)
    end
  end

end
