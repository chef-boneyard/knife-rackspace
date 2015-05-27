#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Matt Ray (<matt@opscode.com>)
# Copyright:: Copyright (c) 2009-2012 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife/rackspace_base'
require 'chef/knife/winrm_base'
require 'chef/knife'

class Chef
  class Knife
    class RackspaceServerCreate < Knife

      include Knife::RackspaceBase
      include Chef::Knife::WinrmBase


      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife rackspace server create (options)"

      attr_accessor :initial_sleep_delay

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server; default is 2 (512 MB)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f.to_s },
        :default => 2

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i.to_s }

      option :server_name,
        :short => "-S NAME",
        :long => "--server-name NAME",
        :description => "The server name"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :bootstrap_network,
        :long => "--bootstrap-network LABEL",
        :description => "Use IP address on this network for bootstrap",
        :default => 'public'

      option :private_network,
        :long => "--private-network",
        :description => "Equivalent to --bootstrap-network private",
        :boolean => true,
        :default => false

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username; default is 'root'",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

        option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d }

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :first_boot_attributes,
        :short => "-j JSON_ATTRIBS",
        :long => "--json-attributes",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) },
        :default => {}

      option :rackspace_metadata,
        :short => "-M JSON",
        :long => "--rackspace-metadata JSON",
        :description => "JSON string version of metadata hash to be supplied with the server create call",
        :proc => Proc.new { |m| Chef::Config[:knife][:rackspace_metadata] = JSON.parse(m) },
        :default => ""

      option :rackconnect_wait,
        :long => "--rackconnect-wait",
        :description => "Wait until the Rackconnect automation setup is complete before bootstrapping chef",
        :boolean => true,
        :default => false

      option :rackspace_servicelevel_wait,
        :long => "--rackspace-servicelevel-wait",
        :description => "Wait until the Rackspace service level automation setup is complete before bootstrapping chef",
        :boolean => true,
        :default => false

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
           Chef::Config[:knife][:hints] ||= {}
           name, path = h.split("=")
           Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
        }

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default",
        :boolean => true,
        :default => true

      option :tcp_test_ssh,
        :long => "--[no-]tcp-test-ssh",
        :description => "Check that SSH is available using a TCP check directly on port 22, enabled by default",
        :boolean => true,
        :default => true

      option :ssh_wait_timeout,
        :long => "--ssh-wait-timeout TIMEOUT",
        :description => "The ssh wait timeout, before attempting ssh",
        :default => "0"

      option :default_networks,
        :long => "--[no-]default-networks",
        :description => "Include public and service networks, enabled by default",
        :boolean => true,
        :default => true

      option :network,
        :long => '--network [LABEL_OR_ID]',
        :description => "Add private network. Use multiple --network options to specify multiple networks.",
        :proc => Proc.new{ |name|
          Chef::Config[:knife][:rackspace_networks] ||= []
          (Chef::Config[:knife][:rackspace_networks] << name).uniq!
        }

      option :bootstrap_protocol,
        :long => "--bootstrap-protocol protocol",
        :description => "Protocol to bootstrap Windows servers. options: winrm",
        :default => nil

      option :server_create_timeout,
        :long => "--server-create-timeout timeout",
        :description => "How long to wait until the server is ready; default is 1200 seconds",
        :default => 1200,
        :proc => Proc.new { |v| Chef::Config[:knife][:server_create_timeout] = v}

      option :bootstrap_proxy,
        :long => "--bootstrap-proxy PROXY_URL",
        :description => "The proxy server for the node being bootstrapped",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_proxy] = v }

      option :rackspace_disk_config,
        :long => "--rackspace-disk-config DISKCONFIG",
        :description => "Specify if want to manage your own disk partitioning scheme (AUTO or MANUAL), default is AUTO",
        :proc => Proc.new { |k| Chef::Config[:knife][:rackspace_disk_config] = k },
        :default => "AUTO"

      option :rackspace_config_drive,
        :long => "--rackspace_config_drive CONFIGDRIVE",
        :description => "Creates a config drive device in /dev/disk/by-label/config-2 if set to TRUE",
        :proc => Proc.new { |k| Chef::Config[:knife][:rackspace_config_drive] = k },
        :default => "false"

      option :rackspace_user_data_file,
        :long => "--rackspace_user_data_file USERDATA",
        :description => "User data file will be placed in the openstack/latest/user_data directory on the config drive",
        :proc => Proc.new { |k| Chef::Config[:knife][:rackspace_user_data] = k }

      option :ssh_keypair,
        :long => "--ssh-keypair KEYPAIR_NAME",
        :description => "Name of existing nova SSH keypair. Public key will be injected into the instance.",
        :proc => Proc.new { |v| Chef::Config[:knife][:rackspace_ssh_keypair] = v },
        :default => nil

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => Proc.new { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :volume_id,
        :long => "--volume-id UUID",
        :description => "UUID of a Cloud Block Storage volume to boot the server from",
        :proc => Proc.new { |vol_id| Chef::Config[:knife][:cbs_volume_id] = vol_id.to_s }

      option :volume_name,
        :long => "--volume-name NAME",
        :description => "Create a Cloud Block Storage device with the specified name",
        :proc => Proc.new { |name| Chef::Config[:knife][:volume_name] = name },
        :default => nil

      option :volume_size,
        :long => "--volume-size SIZE",
        :description => "Amount of storage (in GB, 100-1000) to allocate for the Cloud Block Storage device (defaults to 100)",
        :proc => Proc.new { |size| Chef::Config[:knife][:volume_size] = size },
        :default => 100

      option :volume_type,
        :long => "--volume-type {SSD|SATA}",
        :description => "Type of volume for the Cloud Block Storage device (defaults to SATA)",
        :proc => Proc.new { |voltype| Chef::Config[:knife][:volume_type] = voltype },
        :default => 'SATA'

      option :device_name,
        :long => "--device-name NAME",
        :description => "Name of device for attached Cloug Block Storage volume (Valid device names are `/dev/xvd[a-p]`, default is /dev/xvdb)",
        :proc => Proc.new { |name| Chef::Config[:knife][:device_name] = name },
        :default => '/dev/xvdb'

      def load_winrm_deps
        require 'winrm'
        require 'em-winrm'
        require 'chef/knife/bootstrap_windows_winrm'
        require 'chef/knife/core/windows_bootstrap_context'
        require 'chef/knife/winrm'
      end

      def tcp_test_ssh(hostname)
        sleep config[:ssh_wait_timeout].to_i

        # if this feature is disabled, just return true to skip it
        return true if not config[:tcp_test_ssh]

        ssh_port = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
        tcp_socket = TCPSocket.new(hostname, ssh_port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end


      def parse_file_argument(arg)
        dest, src = arg.split('=')
        unless dest && src
          ui.error "Unable to process file arguments #{arg}. The --file option requires both the destination on the remote machine as well as the local source be supplied using the form DESTINATION-PATH=SOURCE-PATH"
          exit 1
        end
        [dest, src]
      end

      def encode_file(file)
        begin
          filename = File.expand_path(file)
          content = File.read(filename)
        rescue Errno::ENOENT => e
          ui.error "Unable to read source file - #{filename}"
          exit 1
        end
        Base64.encode64(content)
      end

      def files
        return {} unless  Chef::Config[:knife][:file]

        files = []
        Chef::Config[:knife][:file].each do |arg|
          dest, src = parse_file_argument(arg)
          Chef::Log.debug("Inject file #{src} into #{dest}")
          files << {
            :path => dest,
            :contents => encode_file(src)
          }
      end
      files
    end



      def tcp_test_winrm(hostname, port)
        TCPSocket.new(hostname, port)
        return true
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      rescue Errno::ENETUNREACH
        sleep 2
        false
      end


      def run
        $stdout.sync = true

        # Maybe deprecate this option at some point
        config[:bootstrap_network] ||= 'public'
        config[:bootstrap_network] = 'private' if config[:private_network]

        unless Chef::Config[:knife][:image]
          ui.error("You have not provided a valid image value.  Please note the short option for this value recently changed from '-i' to '-I'.")
          exit 1
        end

        if locate_config_value(:bootstrap_protocol) == 'winrm'
          load_winrm_deps
        end

        node_name = get_node_name(config[:chef_node_name] || config[:server_name])
        networks = get_networks(Chef::Config[:knife][:rackspace_networks])

        rackconnect_wait = Chef::Config[:knife][:rackconnect_wait] || config[:rackconnect_wait]
        rackspace_servicelevel_wait = Chef::Config[:knife][:rackspace_servicelevel_wait] || config[:rackspace_servicelevel_wait]

        server_opts = {
          :name => node_name,
          :image_id => Chef::Config[:knife][:image],
          :flavor_id => locate_config_value(:flavor),
          :metadata => Chef::Config[:knife][:rackspace_metadata],
          :disk_config => Chef::Config[:knife][:rackspace_disk_config],
          :user_data => user_data,
          :config_drive => locate_config_value(:rackspace_config_drive) || false,
          :personality => files,
          :key_name => Chef::Config[:knife][:rackspace_ssh_keypair]
        }.tap do |opts|
          if Chef::Config[:knife][:cbs_volume_id] # boot from specified volume
            stdout("\n#{ui.color("Boot from existing Cloud Block Storage volume", :magenta)}")
            msg_pair("CBS Volume ID:", Chef::Config[:knife][:cbs_volume_id])
            opts[:image_id] = ''
            opts[:boot_volume_id] = Chef::Config[:knife][:cbs_volume_id]
          elsif Chef::Config[:knife][:volume_name] && Chef::Config[:knife][:image]  # create a new volume for the specified image with the specified name
            stdout("\n#{ui.color("Boot from new Block Storage volume", :magenta)}")
            msg_pair("CBS Source Image:", Chef::Config[:knife][:image])
            opts[:image_id] = ''
            opts[:boot_volume_id] = create_cbs_volume.id
          end

        end

        server = connection.servers.new(server_opts)

        if version_one?
          server.save
        else
          server.save(:networks => networks)
        end

        msg_pair("Instance ID", server.id)
        msg_pair("Host ID", server.host_id)
        msg_pair("Name", server.name)
        msg_pair("Flavor", server.flavor.name)
        msg_pair("Image", (server.image && server.image.name) || 'None')
        msg_pair("Metadata", server.metadata.all)
        msg_pair("ConfigDrive", server.config_drive)
        msg_pair("UserData", Chef::Config[:knife][:rackspace_user_data])
        msg_pair("RackConnect Wait", rackconnect_wait ? 'yes' : 'no')
        msg_pair("ServiceLevel Wait", rackspace_servicelevel_wait ? 'yes' : 'no')
        msg_pair("SSH Key", Chef::Config[:knife][:rackspace_ssh_keypair])



        # wait for it to be ready to do stuff
        begin
          server.wait_for(Integer(locate_config_value(:server_create_timeout))) {
            print ".";
            Chef::Log.debug("#{progress}%")
            if rackconnect_wait and rackspace_servicelevel_wait
              Chef::Log.debug("rackconnect_automation_status: #{metadata.all['rackconnect_automation_status']}")
              Chef::Log.debug("rax_service_level_automation: #{metadata.all['rax_service_level_automation']}")
              ready? and metadata.all['rackconnect_automation_status'] == 'DEPLOYED' and metadata.all['rax_service_level_automation'] == 'Complete'
            elsif rackconnect_wait
              Chef::Log.debug("rackconnect_automation_status: #{metadata.all['rackconnect_automation_status']}")
              ready? and metadata.all['rackconnect_automation_status'] == 'DEPLOYED'
            elsif rackspace_servicelevel_wait
              Chef::Log.debug("rax_service_level_automation: #{metadata.all['rax_service_level_automation']}")
              ready? and metadata.all['rax_service_level_automation'] == 'Complete'
            else
              ready?
            end
          }
        rescue Fog::Errors::TimeoutError
          ui.error('Timeout waiting for the server to be created')
          msg_pair('Progress', "#{server.progress}%")
          msg_pair('rackconnect_automation_status', server.metadata.all['rackconnect_automation_status'])
          msg_pair('rax_service_level_automation', server.metadata.all['rax_service_level_automation'])
          Chef::Application.fatal! 'Server didn\'t finish on time'
        end
        msg_pair("Metadata", server.metadata)
        if(networks && Chef::Config[:knife][:rackspace_networks])
          msg_pair("Networks", Chef::Config[:knife][:rackspace_networks].sort.join(', '))
        end

        stdout("\n#{ui.color("Waiting server", :magenta)}")

        stdout("\n")

        msg_pair("Public DNS Name", public_dns_name(server))
        msg_pair("Public IP Address", ip_address(server, 'public'))
        msg_pair("Private IP Address", ip_address(server, 'private'))
        msg_pair("Password", server.password)
        msg_pair("Metadata", server.metadata.all)

        if Chef::Config[:knife][:volume_name] && !server_opts[:boot_volume_id]
          Chef::Log.debug("Attaching Cloud Block Storage Volume:")
          device_name = (Chef::Config[:knife][:device_name] || '/dev/xvdb')
          Chef::Log.debug("Device name: #{device_name}")
          server.attach_volume create_cbs_volume.id, device_name
        end

        bootstrap_ip_address = ip_address(server, config[:bootstrap_network])
        Chef::Log.debug("Bootstrap IP Address #{bootstrap_ip_address}")
        if bootstrap_ip_address.nil?
          ui.error("No IP address available for bootstrapping.")
          exit 1
        end

      if locate_config_value(:bootstrap_protocol) == 'winrm'
        stdout "\n#{ui.color("Waiting for winrm", :magenta)}"
        stdout("\nattempting connection to #{bootstrap_ip_address}") until tcp_test_winrm(bootstrap_ip_address, locate_config_value(:winrm_port))
        bootstrap_for_windows_node(server, bootstrap_ip_address).run
      else
        stdout "\n#{ui.color("Waiting for sshd", :magenta)}"
        stdout("\n...waiting for  #{bootstrap_ip_address}") until tcp_test_ssh(bootstrap_ip_address) {
          sleep @initial_sleep_delay ||= 10
          stdout("done")
        }
        bootstrap_for_node(server, bootstrap_ip_address).run
      end

        stdout "\n"
        msg_pair("Instance ID", server.id)
        msg_pair("Host ID", server.host_id)
        msg_pair("Name", server.name)
        msg_pair("Flavor", server.flavor.name)
        msg_pair("Image", (server.image && server.image.name) || 'None')
        msg_pair("Metadata", server.metadata)
        msg_pair("Public DNS Name", public_dns_name(server))
        msg_pair("Public IP Address", ip_address(server, 'public'))
        msg_pair("Private IP Address", ip_address(server, 'private'))
        msg_pair("Password", server.password)
        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", run_list.join(', '))
      end

      def user_data
        file = Chef::Config[:knife][:rackspace_user_data]
        return unless file

        begin
          filename = File.expand_path(file)
          content = File.read(filename)
        rescue Errno::ENOENT => e
          ui.error "Unable to read source file - #{filename}"
          exit 1
        end
        content
      end

      def create_cbs_volume
        Chef::Log.debug("Creating new cloud block storage volume")
        Chef::Log.debug("Volume size: #{Chef::Config[:knife][:volume_size]}")
        Chef::Log.debug("Volume name: #{Chef::Config[:knife][:volume_name]}")
        Chef::Log.debug("Volume type: #{Chef::Config[:knife][:volume_type]}")
        volume_size = (Chef::Config[:knife][:volume_size] || 100).to_i
        volume_name = Chef::Config[:knife][:volume_name]
        volume_type_name = Chef::Config[:knife][:volume_type] || 'SATA'
        volume_opts = {size: volume_size, display_name: volume_name, volume_type: volume_type_name}
        # if a knife image was specified, we're going to create this volume from that image.
        # otherwise it will be a bare volume
        volume_opts[:image_id] = Chef::Config[:knife][:image] if Chef::Config[:knife][:image]
        new_volume = block_storage_connection.volumes.create(volume_opts)
        stdout("\n#{ui.color("Waiting for Cloud Block Storage:", :magenta)}")

        new_volume.wait_for(Integer(locate_config_value(:server_create_timeout))) { print "."; ready? }
        stdout("\n#{ui.color("Cloud Block Storage volume created and available", :magenta)}")
        msg_pair("Cloud Block Storage Volume Id:", new_volume.id)
        new_volume
      end

      def bootstrap_for_node(server, bootstrap_ip_address)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [bootstrap_ip_address]
        bootstrap.config[:ssh_user] = config[:ssh_user] || "root"
        bootstrap.config[:ssh_password] = server.password
        bootstrap.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:distro] = locate_config_value(:distro)  || 'chef-full'
        bootstrap_common_params(bootstrap, server)
      end

      def bootstrap_common_params(bootstrap, server)
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:run_list] = run_list
        if version_one?
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        else
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.name
        end
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:first_boot_attributes] = config[:first_boot_attributes]
        bootstrap.config[:bootstrap_proxy] = locate_config_value(:bootstrap_proxy)
        bootstrap.config[:encrypted_data_bag_secret] = config[:encrypted_data_bag_secret]
        bootstrap.config[:encrypted_data_bag_secret_file] = config[:encrypted_data_bag_secret_file]
        bootstrap.config[:secret] = locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)  || ""

        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["rackspace"] ||= {}
        bootstrap
      end

      def bootstrap_for_windows_node(server, bootstrap_ip_address)
        bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
        bootstrap.name_args = [bootstrap_ip_address]
        bootstrap.config[:winrm_user] = locate_config_value(:winrm_user) || 'Administrator'
        bootstrap.config[:winrm_password] = locate_config_value(:winrm_password) || server.password
        bootstrap.config[:winrm_transport] = locate_config_value(:winrm_transport)
        bootstrap.config[:winrm_port] = locate_config_value(:winrm_port)
        bootstrap.config[:distro] = locate_config_value(:distro)  || 'windows-chef-client-msi'
        bootstrap_common_params(bootstrap, server)
      end

    end

    def run_list
      config[:run_list] || []
    end
    private :run_list

    #v2 servers require a name, random if chef_node_name is empty, empty if v1
    def get_node_name(chef_node_name)
      return chef_node_name unless chef_node_name.nil?
      #lazy uuids
      chef_node_name = "rs-"+rand.to_s.split('.')[1] unless version_one?
    end

    def get_networks(names)
      names = Array(names)
      if(Chef::Config[:knife][:rackspace_version] == 'v2')
        if(config[:default_networks])
          nets = [
            '00000000-0000-0000-0000-000000000000',
            '11111111-1111-1111-1111-111111111111'
          ]
        else
          nets = []
        end
        available_networks = connection.networks.all

        names.each do |name|
          net = available_networks.detect{|n| n.label == name || n.id == name}
          if(net)
            nets << net.id
          else
            ui.error("Failed to locate network: #{name}")
            exit 1
          end
        end
        nets
      elsif(names && !names.empty?)
        ui.error("Custom networks are only available in v2 API")
        exit 1
      end
    end
  end
end
