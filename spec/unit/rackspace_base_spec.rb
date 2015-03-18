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
    let(:fog_connection) { double(Fog::Compute) }

    before do
      allow(Chef::Knife::UI).to receive(:new).and_return(ui)
      allow(Fog::Compute).to receive(:new).and_return(fog_connection)
      Chef::Config[:knife][:rackspace_region] = :ord
    end

    it 'raises a ui error and exits unless rackspace region has been set' do
      expect(ui).to receive(:error).with(/Please specify region/)

      Chef::Config[:knife][:rackspace_region] = nil

      expect{ tester.connection }.to raise_error(SystemExit)
    end

    context 'when rackspace api is version one' do
      it 'returns a fog connection initialized with a version 1 option' do
        Chef::Config[:knife][:rackspace_version] = 'v1'

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(version: 'v1'))
          .and_return(fog_connection)

        expect(tester.connection).to eq(fog_connection)
      end
    end

    context 'when rackspace api is version two' do
      it 'returns a fog connection initialized with a version 2 option' do
        Chef::Config[:knife][:rackspace_version] = 'v2'

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(version: 'v2'))
          .and_return(fog_connection)

        expect(tester.connection).to eq(fog_connection)
      end
    end

    it 'sets provider option to "Rackspace"' do
      expect(Fog::Compute).to receive(:new)
        .with(hash_including(provider: 'Rackspace'))

      tester.connection
    end

    it 'sets rackspace api key option to currently configured api key' do
      api_key = 'test_key'
      Chef::Config[:knife][:rackspace_api_key] = api_key

      expect(Fog::Compute).to receive(:new)
        .with(hash_including(rackspace_api_key: api_key))

      tester.connection
    end

    context 'when chef is configured with rackspace username' do
      it 'sets rackspace username option to chef rackspace username' do
        username = 'test_username'
        Chef::Config[:knife][:rackspace_username] = username

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(rackspace_username: username))

        tester.connection
      end
    end

    context 'when chef is not configured with a rackspace username' do
      it 'sets rackspace username option to chef racspace api_username' do
        api_username = 'test_api_username'
        Chef::Config[:knife][:rackspace_username] = nil
        Chef::Config[:knife][:rackspace_api_username] = api_username

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(rackspace_username: api_username))

        tester.connection
      end
    end

    it 'sets rackspace auth url option to correct auth endpoint' do
      test_url = "http://test-url.com"
      Chef::Config[:knife][:rackspace_auth_url] = test_url

      expect(Fog::Compute).to receive(:new)
        .with(hash_including(rackspace_auth_url: test_url))

      tester.connection
    end

    it 'sets rackspace region option to configured rackspace region' do
      test_region = :lon
      Chef::Config[:knife][:rackspace_region] = test_region

      expect(Fog::Compute).to receive(:new)
        .with(hash_including(rackspace_region: test_region))

      tester.connection
    end

    context 'when chef config has an https proxy' do
      it 'sets the proxy connection option to the https proxy value' do
        https_proxy = 'test_https_proxy'
        Chef::Config[:https_proxy] = https_proxy

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(connection_options: hash_including({proxy: https_proxy})))

        tester.connection
      end
    end

    context 'when chef config has an http proxy' do
      it 'sets the proxy connection option to the http proxy value' do
        http_proxy = 'test_http_proxy'
        Chef::Config[:https_proxy] = nil
        Chef::Config[:http_proxy] = http_proxy

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(connection_options: hash_including({proxy: http_proxy})))

        tester.connection
      end
    end

    context 'when chef config has both an https and an http proxy' do
      it 'sets the proxy connection option to the https proxy value' do
        https_proxy = 'test_https_proxy'
        http_proxy = 'test_http_proxy'
        Chef::Config[:https_proxy] = https_proxy
        Chef::Config[:http_proxy] = http_proxy

        expect(Fog::Compute).to receive(:new)
          .with(hash_including(connection_options: hash_including({proxy: https_proxy})))

        tester.connection
      end
    end

    it 'sets the ssl verify peer connection option if it is configured' do
      ssl_verify_peer = 'test_verify_peer'
      Chef::Config[:knife][:ssl_verify_peer] = ssl_verify_peer

      expect(Fog::Compute).to receive(:new)
        .with(hash_including(connection_options: hash_including({ssl_verify_peer: ssl_verify_peer})))

      tester.connection
    end

  end

  describe '#block_storage_connection' do
    let(:fog_connection) { double(Fog::Rackspace::BlockStorage) }

    it 'returns a Fog block storage connection initialized with block storage connection params' do
      Chef::Config[:knife][:rackspace_version] = 'v2'
      Chef::Config[:knife][:rackspace_region] = :ord
      expect(Fog::Rackspace::BlockStorage).to receive(:new).and_return(fog_connection)

      expect(tester.block_storage_connection).to eq(fog_connection)
    end
  end

end
