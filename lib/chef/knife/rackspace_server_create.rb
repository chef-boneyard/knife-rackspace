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

class Chef
  class Knife
    class RackspaceServerCreate < Knife

      include Knife::RackspaceBase

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife rackspace server create (options)"

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server; default is 2 (512 MB)",
        :proc => Proc.new { |f| Chef::Config[:knife][:flavor] = f.to_i },
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

      option :private_network,
        :long => "--private-network",
        :description => "Use the private IP for bootstrapping rather than the public IP",
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
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "chef-full"

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

      option :default_networks,
        :long => "--[no-]-default-networks",
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

      def tcp_test_ssh(hostname)
        tcp_socket = TCPSocket.new(hostname, 22)
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

      def run
        $stdout.sync = true

        unless Chef::Config[:knife][:image]
          ui.error("You have not provided a valid image value.  Please note the short option for this value recently changed from '-i' to '-I'.")
          exit 1
        end

        node_name = get_node_name(config[:chef_node_name] || config[:server_name])
        networks = get_networks(Chef::Config[:knife][:rackspace_networks])

        server = connection.servers.new(
          :name => node_name,
          :image_id => Chef::Config[:knife][:image],
          :flavor_id => locate_config_value(:flavor),
          :metadata => Chef::Config[:knife][:rackspace_metadata]
        )
        server.save(
          :networks => networks
        )

        msg_pair("Instance ID", server.id)
        msg_pair("Host ID", server.host_id)
        msg_pair("Name", server.name)
        msg_pair("Flavor", server.flavor.name)
        msg_pair("Image", server.image.name)
        msg_pair("Metadata", server.metadata)
        if(networks && Chef::Config[:knife][:rackspace_networks])
          msg_pair("Networks", Chef::Config[:knife][:rackspace_networks].sort.join(', '))
        end

        print "\n#{ui.color("Waiting server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts("\n")

        msg_pair("Public DNS Name", public_dns_name(server))
        msg_pair("Public IP Address", public_ip(server))
        msg_pair("Private IP Address", private_ip(server))
        msg_pair("Password", server.password)

        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        #which IP address to bootstrap
        bootstrap_ip_address = public_ip(server)
        if config[:private_network]
          bootstrap_ip_address = private_ip(server)
        end
        Chef::Log.debug("Bootstrap IP Address #{bootstrap_ip_address}")
        if bootstrap_ip_address.nil?
          ui.error("No IP address available for bootstrapping.")
          exit 1
        end

        print(".") until tcp_test_ssh(bootstrap_ip_address) {
          sleep @initial_sleep_delay ||= 10
          puts("done")
        }
        bootstrap_for_node(server, bootstrap_ip_address).run

        puts "\n"
        msg_pair("Instance ID", server.id)
        msg_pair("Host ID", server.host_id)
        msg_pair("Name", server.name)
        msg_pair("Flavor", server.flavor.name)
        msg_pair("Image", server.image.name)
        msg_pair("Metadata", server.metadata)
        msg_pair("Public DNS Name", public_dns_name(server))
        msg_pair("Public IP Address", public_ip(server))
        msg_pair("Private IP Address", private_ip(server))
        msg_pair("Password", server.password)
        msg_pair("Environment", config[:environment] || '_default')
        msg_pair("Run List", config[:run_list].join(', '))
      end

      def bootstrap_for_node(server, bootstrap_ip_address)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [bootstrap_ip_address]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:first_boot_attributes] = config[:first_boot_attributes]
        bootstrap.config[:ssh_user] = config[:ssh_user] || "root"
        bootstrap.config[:ssh_password] = server.password
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        if version_one?
          bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        else
          bootstrap.config[:chef_node_name] = server.name
        end
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["rackspace"] ||= {}
        bootstrap
      end

    end
    #v2 servers require a name, random if chef_node_name is empty, empty if v1
    def get_node_name(chef_node_name)
      return chef_node_name unless chef_node_name.nil?
      #lazy uuids
      chef_node_name = "rs-"+rand.to_s.split('.')[1] unless version_one?
    end

    def get_networks(names)
      names = Array(names) unless names.is_a?(Array)
      if(Chef::Config[:knife][:rackspace_version] == 'v2')
        if(config[:default_networks])
          nets = [
            '00000000-0000-0000-0000-000000000000',
            '11111111-1111-1111-1111-111111111111'
          ]
        else
          nets = []
        end
        found_nets = connection.networks.find_all do |n|
          names.include?(n.label) || names.include?(n.id)
        end
        
        names.each do |name|
          net = found_nets.detect{|n| n.label == name || n.id == name}
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
