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
      allow(fog_compute_connection).to receive_message_chain('networks.all').and_return([])
    end

    it 'raises a ui error and exits unless image option has been set' do
      expect(ui).to receive(:error).with(/You have not provided.*image/)

      Chef::Config[:knife][:image] = nil

      expect{ creator.run }.to raise_error(SystemExit)
    end

    it 'creates a new server instance and tries to save it' do
      Chef::Config[:knife][:image] = image.name

      expect(fog_compute_connection).to receive(:servers).and_return(servers)
      expect(servers).to receive(:new).and_return(server)
      expect(server).to receive(:save)

      creator.run
    end

  end

end
