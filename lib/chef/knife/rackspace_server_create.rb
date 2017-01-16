#
# Author:: Adam Jacob (<adam@chef.io>)
# Author:: Matt Ray (<matt@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
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

require "chef/knife/rackspace_base"
require "chef/knife/winrm_base"
require "chef/knife"

class Chef
  class Knife
    class RackspaceServerCreate < Knife

      include Knife::RackspaceBase
      include Chef::Knife::WinrmBase

      deps do
        require "fog/rackspace"
        require "readline"
        require "chef/json_compat"
        require "chef/knife/bootstrap"
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife rackspace server create (options)"

      attr_accessor :initial_sleep_delay

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server; default is 2 (512 MB)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f.to_s },
        :default => "2"

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i.to_s }

      option :boot_volume_size,
        :long => "--boot-volume-size GB",
        :description => "The size of the CBS to use as the server's boot device",
        :proc => Proc.new { |i| Chef::Config[:knife][:boot_volume_size] = i.to_s },
        :default => 100

      option :boot_volume_id,
        :short => "-B BOOT_VOLUME_ID",
        :long => "--boot-volume-id UUID",
        :description => "The image CBS UUID to use as the server's boot device",
        :proc => Proc.new { |i| Chef::Config[:knife][:boot_volume_id] = i.to_s }

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
        :default => "public"

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
        :description => "Install the pre-release chef gems",
        :default => false

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
        :proc => lambda { |m| JSON.parse(m) },
        :default => {}

      option :rackconnect_wait,
        :long => "--rackconnect-wait",
        :description => "Wait until the Rackconnect automation setup is complete before bootstrapping chef",
        :boolean => true,
        :default => false

      option :rackconnect_v3_network_id,
        :long => "--rackconnect-v3-network-id ID",
        :description => "Rackconnect V3 ONLY: Link a new server to an existing network",
        :proc => lambda { |o| Chef::Config[:knife][:rackconnect_v3_network_id] = o },
        :default => nil

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

      option :retry_ssh_every,
        :long => "--retry-ssh-every TIMEOUT",
        :description => "Retry SSH after n seconds (retry each period)",
        :default => "5"

      option :retry_ssh_limit,
        :long => "--retry-ssh-limit COUNT",
        :description => "Retry SSH at most this number of times",
        :default => "5"

      option :default_networks,
        :long => "--[no-]default-networks",
        :description => "Include public and service networks, enabled by default",
        :boolean => true,
        :default => true

      option :network,
        :long => "--network [LABEL_OR_ID]",
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
        :proc => Proc.new { |v| Chef::Config[:knife][:server_create_timeout] = v }

      option :bootstrap_proxy,
        :long => "--bootstrap-proxy PROXY_URL",
        :description => "The proxy server for the node being bootstrapped",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_proxy] = v }

      option :rackspace_disk_config,
        :long => "--rackspace-disk-config DISKCONFIG",
        :description => "Specify if want to manage your own disk partitioning scheme (AUTO or MANUAL)",
        :proc => Proc.new { |k| Chef::Config[:knife][:rackspace_disk_config] = k }

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

      option :secret,
        :long => "--secret",
        :description => "The secret key to us to encrypt data bag item values",
        :proc => lambda { |s| Chef::Config[:knife][:secret] = s }

      option :secret_file,
        :long => "--secret-file SECRET_FILE",
        :description => "A file containing the secret key to use to encrypt data bag item values",
        :proc => lambda { |sf| Chef::Config[:knife][:secret_file] = sf }

      option :bootstrap_vault_file,
        :long        => "--bootstrap-vault-file VAULT_FILE",
        :description => "A JSON file with a list of vault(s) and item(s) to be updated"

      option :bootstrap_vault_json,
        :long        => "--bootstrap-vault-json VAULT_JSON",
        :description => "A JSON string with the vault(s) and item(s) to be updated"

      option :bootstrap_vault_item,
        :long        => "--bootstrap-vault-item VAULT_ITEM",
        :description => 'A single vault and item to update as "vault:item"',
        :proc        => Proc.new { |i|
          (vault, item) = i.split(/:/)
          Chef::Config[:knife][:bootstrap_vault_item] ||= {}
          Chef::Config[:knife][:bootstrap_vault_item][vault] ||= []
          Chef::Config[:knife][:bootstrap_vault_item][vault].push(item)
          Chef::Config[:knife][:bootstrap_vault_item]
        }

      def load_winrm_deps
        require "winrm"
        require "chef/knife/winrm"
        require "chef/knife/bootstrap_windows_winrm"
        require "chef/knife/core/windows_bootstrap_context"
      end

      def tcp_test_ssh(server, bootstrap_ip)
        return true unless locate_config_value(:tcp_test_ssh) != nil

        limit = locate_config_value(:retry_ssh_limit).to_i
        count = 0

        begin
          Net::SSH.start(bootstrap_ip, "root", :password => server.password ) do |ssh|
            Chef::Log.debug("sshd accepting connections on #{bootstrap_ip}")
            break
          end
        rescue
          count += 1

          if count <= limit
            print "."
            sleep locate_config_value(:retry_ssh_every).to_i
            tcp_test_ssh(server, bootstrap_ip)
          else
            ui.error "Unable to SSH into #{bootstrap_ip}"
            exit 1
          end
        end
      end

      def parse_file_argument(arg)
        dest, src = arg.split("=")
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
        return {} unless Chef::Config[:knife][:file]

        files = []
        Chef::Config[:knife][:file].each do |arg|
          dest, src = parse_file_argument(arg)
          Chef::Log.debug("Inject file #{src} into #{dest}")
          files << {
            :path => dest,
            :contents => encode_file(src),
          }
        end
        files
      end

      def tcp_test_winrm(hostname, port)
        tcp_socket = TCPSocket.new(hostname, port)
        yield
        true
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
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true

        server_create_options = {
          :metadata => locate_config_value(:rackspace_metadata),
          :disk_config => locate_config_value(:rackspace_disk_config),
          :user_data => user_data,
          :config_drive => locate_config_value(:rackspace_config_drive) || false,
          :personality => files,
          :key_name => locate_config_value(:rackspace_ssh_keypair),
          :name => get_node_name(config[:chef_node_name] || config[:server_name]),
          :networks => get_networks(locate_config_value(:rackspace_networks), locate_config_value(:rackconnect_v3_network_id)),
        }

        # Maybe deprecate this option at some point
        config[:bootstrap_network] = "private" if locate_config_value(:private_network)

        flavor_id = locate_config_value(:flavor)
        flavor = connection.flavors.get(flavor_id)
        if !flavor
          ui.error("Invalid Flavor ID: #{flavor_id}")
          exit 1
        else
          server_create_options[:flavor_id] = flavor.id
        end

        # This is somewhat a hack, but Rackspace's API returns '0' for flavors
        # that must be backed by a CBS volume.
        #
        # In the case we are trying to create one of these flavors, we should
        # swap out the image_id argument with the boot_image_id argument.
        if flavor.disk == 0
          server_create_options[:image_id] = ""
          server_create_options[:boot_volume_id] = locate_config_value(:boot_volume_id)
          server_create_options[:boot_image_id] = locate_config_value(:image)
          server_create_options[:boot_volume_size] = locate_config_value(:boot_volume_size)

          if server_create_options[:boot_image_id] && server_create_options[:boot_volume_id]
            ui.error("Please specify either --boot-volume-id (-B) or --image (-I)")
            exit 1
          end
        else
          server_create_options[:image_id] = locate_config_value(:image)

          if !server_create_options[:image_id]
            ui.error("Please specify an Image ID for the server with --image (-I)")
            exit 1
          end
        end

        if locate_config_value(:bootstrap_protocol) == "winrm"
          load_winrm_deps
        end

        server = connection.servers.new(server_create_options)

        if version_one?
          server.save
        else
          server.save(:networks => server_create_options[:networks])
        end

        rackconnect_wait = locate_config_value(:rackconnect_wait)
        rackspace_servicelevel_wait = locate_config_value(:rackspace_servicelevel_wait)

        msg_pair("Instance ID", server.id)
        msg_pair("Host ID", server.host_id)
        msg_pair("Name", server.name)
        msg_pair("Flavor", server.flavor.name)
        msg_pair("Image", server.image.name) if server.image
        msg_pair("Boot Image ID", server.boot_image_id) if server.boot_image_id
        msg_pair("Metadata", server.metadata.all)
        msg_pair("ConfigDrive", server.config_drive)
        msg_pair("UserData", locate_config_value(:rackspace_user_data))
        msg_pair("RackConnect Wait", rackconnect_wait ? "yes" : "no")
        msg_pair("RackConnect V3", locate_config_value(:rackconnect_v3_network_id) ? "yes" : "no")
        msg_pair("ServiceLevel Wait", rackspace_servicelevel_wait ? "yes" : "no")
        msg_pair("SSH Key", locate_config_value(:rackspace_ssh_keypair))

        # wait for it to be ready to do stuff
        begin
          server.wait_for(Integer(locate_config_value(:server_create_timeout))) do
            print ".";
            Chef::Log.debug("#{progress}%")

            if rackconnect_wait && rackspace_servicelevel_wait
              Chef::Log.debug("rackconnect_automation_status: #{metadata.all['rackconnect_automation_status']}")
              Chef::Log.debug("rax_service_level_automation: #{metadata.all['rax_service_level_automation']}")
              ready? && metadata.all["rackconnect_automation_status"] == "DEPLOYED" && metadata.all["rax_service_level_automation"] == "Complete"
            elsif rackconnect_wait
              Chef::Log.debug("rackconnect_automation_status: #{metadata.all['rackconnect_automation_status']}")
              ready? && metadata.all["rackconnect_automation_status"] == "DEPLOYED"
            elsif rackspace_servicelevel_wait
              Chef::Log.debug("rax_service_level_automation: #{metadata.all['rax_service_level_automation']}")
              ready? && metadata.all["rax_service_level_automation"] == "Complete"
            else
              ready?
            end
          end
        rescue Fog::Errors::TimeoutError
          ui.error("Timeout waiting for the server to be created")
          msg_pair("Progress", "#{server.progress}%")
          msg_pair("rackconnect_automation_status", server.metadata.all["rackconnect_automation_status"])
          msg_pair("rax_service_level_automation", server.metadata.all["rax_service_level_automation"])
          Chef::Application.fatal! 'Server didn\'t finish on time'
        end

        msg_pair("Metadata", server.metadata)

        print "\n#{ui.color("Waiting server", :magenta)}"

        puts("\n")

        if locate_config_value(:rackconnect_v3_network_id)
          print "\n#{ui.color("Setting up RackconnectV3 network and IPs", :magenta)}"
          setup_rackconnect_network!(server)
          while server.ipv4_address == ""
            server.reload
            sleep 5
          end
        end

        if server_create_options[:networks] && locate_config_value(:rackspace_networks)
          msg_pair("Networks", locate_config_value(:rackspace_networks).sort.join(", "))
        end

        msg_pair("Public DNS Name", public_dns_name(server))
        msg_pair("Public IP Address", ip_address(server, "public"))
        msg_pair("Private IP Address", ip_address(server, "private"))
        msg_pair("Password", server.password)
        msg_pair("Metadata", server.metadata.all)

        bootstrap_ip_address = ip_address(server, locate_config_value(:bootstrap_network))

        Chef::Log.debug("Bootstrap IP Address #{bootstrap_ip_address}")
        if bootstrap_ip_address.nil?
          ui.error("No IP address available for bootstrapping.")
          exit 1
        end

        if locate_config_value(:bootstrap_protocol) == "winrm"
          print "\n#{ui.color("Waiting for winrm", :magenta)}"
          print(".") until tcp_test_winrm(bootstrap_ip_address, locate_config_value(:winrm_port))
          bootstrap_for_windows_node(server, bootstrap_ip_address).run
        else
          print "\n#{ui.color("Waiting for sshd", :magenta)}"
          tcp_test_ssh(server, bootstrap_ip_address)
          bootstrap_for_node(server, bootstrap_ip_address).run
        end

        puts "\n"
        msg_pair("Instance ID", server.id)
        msg_pair("Host ID", server.host_id)
        msg_pair("Name", server.name)
        msg_pair("Flavor", server.flavor.name)
        msg_pair("Image", server.image.name) if server.image
        msg_pair("Boot Image ID", server.boot_image_id) if server.boot_image_id
        msg_pair("Metadata", server.metadata)
        msg_pair("Public DNS Name", public_dns_name(server))
        msg_pair("Public IP Address", ip_address(server, "public"))
        msg_pair("Private IP Address", ip_address(server, "private"))
        msg_pair("Password", server.password)
        msg_pair("Environment", config[:environment] || "_default")
        msg_pair("Run List", config[:run_list].join(", "))
      end

      def setup_rackconnect_network!(server)
        auth_token = connection.authenticate
        tenant_id  = connection.endpoint_uri.path.split("/").last
        region     = connection.region
        uri        = URI("https://#{region}.rackconnect.api.rackspacecloud.com/v3/#{tenant_id}/public_ips")

        Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          begin
            req                 = Net::HTTP::Post.new(uri.request_uri)
            req["X-Auth-Token"] = auth_token
            req["Content-Type"] = "application/json"
            req.body            = JSON.dump("cloud_server" => { "id" => server.id })
            http.use_ssl        = true
            http.request req
          rescue StandardError => e
            puts "HTTP Request failed (#{e.message})"
          end
        end
      end

      def user_data
        file = locate_config_value(:rackspace_user_data)
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

      def bootstrap_for_node(server, bootstrap_ip_address)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [bootstrap_ip_address]
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user) || "root"
        bootstrap.config[:ssh_password] = server.password
        bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:host_key_verify] = locate_config_value(:host_key_verify)
        bootstrap.config[:bootstrap_vault_file] = locate_config_value(:bootstrap_vault_file) if locate_config_value(:bootstrap_vault_file)
        bootstrap.config[:bootstrap_vault_json] = locate_config_value(:bootstrap_vault_json) if locate_config_value(:bootstrap_vault_json)
        bootstrap.config[:bootstrap_vault_item] = locate_config_value(:bootstrap_vault_item) if locate_config_value(:bootstrap_vault_item)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless locate_config_value(:ssh_user) == "root"
        bootstrap.config[:distro] = locate_config_value(:distro) || "chef-full"
        bootstrap_common_params(bootstrap, server)
      end

      def bootstrap_common_params(bootstrap, server)
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:run_list] = config[:run_list]
        if version_one?
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        else
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.name
        end
        bootstrap.config[:prerelease] = locate_config_value(:prerelease)
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:first_boot_attributes] = locate_config_value(:first_boot_attributes)
        bootstrap.config[:bootstrap_proxy] = locate_config_value(:bootstrap_proxy)
        bootstrap.config[:encrypted_data_bag_secret] = locate_config_value(:secret)
        bootstrap.config[:encrypted_data_bag_secret_file] = locate_config_value(:secret_file)
        bootstrap.config[:secret] = locate_config_value(:secret)
        bootstrap.config[:secret_file] = locate_config_value(:secret_file)

        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["rackspace"] ||= {}
        bootstrap
      end

      def bootstrap_for_windows_node(server, bootstrap_ip_address)
        bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
        bootstrap.name_args = [bootstrap_ip_address]
        bootstrap.config[:winrm_user] = locate_config_value(:winrm_user) || "Administrator"
        bootstrap.config[:winrm_password] = locate_config_value(:winrm_password) || server.password
        bootstrap.config[:winrm_transport] = locate_config_value(:winrm_transport)
        bootstrap.config[:winrm_port] = locate_config_value(:winrm_port)
        bootstrap.config[:distro] = locate_config_value(:distro) || "windows-chef-client-msi"
        bootstrap_common_params(bootstrap, server)
      end

    end
    #v2 servers require a name, random if chef_node_name is empty, empty if v1
    def get_node_name(chef_node_name)
      return chef_node_name unless chef_node_name.nil?
      #lazy uuids
      chef_node_name = "rs-" + rand.to_s.split(".")[1] unless version_one?
    end

    def get_networks(names, rackconnect3 = false)
      names = Array(names)

      if locate_config_value(:rackspace_version) == "v2"
        nets = if rackconnect3
                 [locate_config_value(:rackconnect_v3_network_id)]
               elsif locate_config_value(:default_networks)
                 [
                   "00000000-0000-0000-0000-000000000000",
                   "11111111-1111-1111-1111-111111111111",
                 ]
               else
                 []
               end

        available_networks = connection.networks.all

        names.each do |name|
          net = available_networks.detect { |n| n.label == name || n.id == name }
          if net
            nets << net.id
          else
            ui.error("Failed to locate network: #{name}")
            exit 1
          end
        end
        nets
      elsif names && !names.empty?
        ui.error("Custom networks are only available in v2 API")
        exit 1
      end
    end
  end
end
