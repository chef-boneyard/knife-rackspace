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

  let(:bootstrap_resource) { double(Chef::Knife::Bootstrap, run: true, config: {},
                                      :name_args= => true) }

  describe '#run' do
    before do

      allow_any_instance_of(Chef::Knife::RackspaceServerCreate).to receive(:tcp_test_ssh).and_return(true)

      allow(ui).to receive(:color) { |label| label }
      allow(Chef::Knife::UI).to receive(:new).and_return(ui)
      allow(Fog::Compute).to receive(:new).and_return(fog_compute_connection)
      allow(Chef::Knife::Bootstrap).to receive(:new).and_return(bootstrap_resource)

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

      it 'bootstraps the created server instance' do
        expect(Chef::Knife::Bootstrap).to receive(:new).and_return(bootstrap_resource)
        expect(bootstrap_resource).to receive(:run)

        #TODO: The Bootstrap configuration logic is complex enough that it deserves to
        #      be extracted to its own class.
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

      context 'when a volume name is specified' do
        let(:volume_name) { 'test volume name' }
        let(:volume) { double('volume', id: rand(1000), wait_for: true) }

        let(:volumes) { double('volumes resource', create: volume) }
        let(:fog_block_storage_connection) { double(Fog::Rackspace::BlockStorage, volumes: volumes) }

        before do
          Chef::Config[:knife][:volume_name] = volume_name

          allow(Fog::Rackspace::BlockStorage).to receive(:new)
            .and_return(fog_block_storage_connection)
          allow(server).to receive(:attach_volume)
        end

        context 'when a volume size is specified' do
          it 'creates a volume with the specified size' do
            size = 200
            Chef::Config[:knife][:volume_size] = size.to_s

            expect(volumes).to receive(:create)
              .with(hash_including(size: size))

            creator.run
          end
        end

        context 'when no volume size is specified' do
          it 'creates a 100GB volume' do
            expect(volumes).to receive(:create)
              .with(hash_including(size: 100))

            creator.run
          end
        end

        context 'when a volume type is specified' do
          it 'creates a volume with the specified type' do
            Chef::Config[:knife][:volume_type] = 'SSD'

            expect(volumes).to receive(:create)
              .with(hash_including(volume_type: 'SSD'))

            creator.run
          end
        end

        context 'when no volume type is specified' do
          it 'creates a SATA volume' do
            expect(volumes).to receive(:create)
              .with(hash_including(volume_type: 'SATA'))

            creator.run
          end
        end

        context 'when a device name is specified' do
          it 'attaches the volume to the specified device name' do
            Chef::Config[:knife][:image] = nil

            device_name = '/dev/xbdc'

            Chef::Config[:knife][:device_name] = device_name

            expect(server).to receive(:attach_volume)
              .with(volume.id, device_name)

            creator.run
          end
        end

        context 'when no device name is specified' do
          it 'attaches the bolume to /dev/xvdb' do
            Chef::Config[:knife][:image] = nil

            expect(server).to receive(:attach_volume)
              .with(volume.id, '/dev/xvdb')

            creator.run
          end
        end

      end

    end
  end

end
