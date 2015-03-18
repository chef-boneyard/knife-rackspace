require 'spec_helper'

require 'chef/knife'
require 'chef/knife/rackspace_server_create'

describe Chef::Knife::RackspaceServerCreate do
  let(:creator) { Chef::Knife::RackspaceServerCreate.new }
  let(:ui) { double(Chef::Knife::UI, error: nil) }
  let(:server_id) { rand(1000) }
  let(:image) {  double('image', name: 'test_image') }
  let(:flavor) { double('flavor', name: 'test flavor name') }
  let(:metadata) { double('metadata', all: {}) }
  let(:ip_address) { '10.0.0.0' }
  let(:addresses) { { "public" => [{"version" => 4, "addr" => ip_address}] } }

  let(:server) { double('server instance', save: true, id: server_id, host_id: 'test host id', name: 'test name',
                          flavor: flavor, image: image, metadata: metadata, config_drive: '', wait_for: true,
                          access_ipv4_address: ip_address, addresses: addresses, password: 'test password') }
  let(:servers) { double('servers resource', new: server) }
  let(:fog_compute_connection) { double(Fog::Compute, servers: servers) }

  describe '#run' do
    before do
      allow_any_instance_of(Chef::Knife::Bootstrap).to receive(:run)
      allow_any_instance_of(Chef::Knife::RackspaceServerCreate).to receive(:tcp_test_ssh).and_return(true)

      allow(ui).to receive(:color) { |label| label }
      allow(Chef::Knife::UI).to receive(:new).and_return(ui)
      allow(Fog::Compute).to receive(:new).and_return(fog_compute_connection)
      Chef::Config[:knife][:server_create_timeout] = 1200
      Chef::Config[:knife][:rackspace_region] = :dfw
      allow(fog_compute_connection).to receive_message_chain('networks.all').and_return([])
    end

    it 'raises a ui error and exits unless image option has been set' do
      expect(ui).to receive(:error).with(/You have not provided.*image/)

      Chef::Config[:knife][:image] = nil

      expect{ creator.run }.to raise_error(SystemExit)
    end

    context 'when all required params are specified' do
      before do
        Chef::Config[:knife][:image] = image.name
      end

      it 'creates a new server instance and tries to save it' do
        expect(fog_compute_connection).to receive(:servers).and_return(servers)
        expect(servers).to receive(:new).and_return(server)
        expect(server).to receive(:save)

        creator.run
      end

      context 'when chef node name is configured' do
        it 'sets server name to chef node name' do
          node_name = 'test_chef_node_name'
          creator.config[:chef_node_name] = node_name

          expect(servers).to receive(:new)
            .with(hash_including(name: node_name))
            .and_return(server)

          creator.run
        end
      end

      context 'when chef node name is not configured' do
        it 'sets server name to configured server name' do
          node_name = 'test_server_name'
          creator.config[:chef_node_name] = nil
          creator.config[:server_name] = node_name

          expect(servers).to receive(:new)
            .with(hash_including(name: node_name))
            .and_return(server)

          creator.run
        end
      end

      it 'sets image id to the configured image' do
        expect(servers).to receive(:new)
          .with(hash_including(image_id: image.name))
          .and_return(server)

        creator.run
      end

      it 'sets flavor id to the configured flavor' do
        Chef::Config[:knife][:flavor] = flavor.name

        expect(servers).to receive(:new)
          .with(hash_including(flavor_id: flavor.name))
          .and_return(server)

        creator.run
      end

      it 'sets metadata to the configured rackspace metadata' do
        Chef::Config[:knife][:rackspace_metadata] = metadata

        expect(servers).to receive(:new)
          .with(hash_including(metadata: metadata))
          .and_return(server)

        creator.run
      end

      it 'sets disk config to the configured rackspace disk config' do
        disk_config = 'test disk config'

        Chef::Config[:knife][:rackspace_disk_config] = disk_config

        expect(servers).to receive(:new)
          .with(hash_including(disk_config: disk_config))
          .and_return(server)

        creator.run
      end

      context 'when a rackspace user data parameter is specified' do
        it 'sets the user data to the contents of the specified file' do
          # pending "Need to find a way to run this test without leaving file cruft around."
          # Maybe write to /tmp
          # use begin/ensure to clean up afterwards, or an after do block
          # need to do the same for personality/files
        end
      end

      it 'sets config drive to the configured rackspace config drive' do
        config_drive = 'test config drive'

        Chef::Config[:knife][:rackspace_config_drive] = config_drive

        expect(servers).to receive(:new)
          .with(hash_including(config_drive: config_drive))
          .and_return(server)

        creator.run
      end

      it 'sets key name to the configured rackspace ssh keypair' do
        ssh_keypair = 'test ssh keypair'

        Chef::Config[:knife][:rackspace_ssh_keypair] = ssh_keypair

        expect(servers).to receive(:new)
          .with(hash_including(key_name: ssh_keypair))
          .and_return(server)

        creator.run
      end


    end
  end

end
