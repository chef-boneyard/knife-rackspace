#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2009 Opscode, Inc.
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
        :proc => Proc.new { |i| Chef::Config[:knife][:image] = i.to_i }

      option :server_name,
        :short => "-S NAME",
        :long => "--server-name NAME",
        :description => "The server name"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

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
        :description => "Bootstrap a distro using a template; default is 'ubuntu10.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu10.04-gems"

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

      option :rackspace_metadata,
        :short => "-M JSON",
        :long => "--rackspace-metadata JSON",
        :description => "JSON string version of metadata hash to be supplied with the server create call",
        :proc => Proc.new { |m| Chef::Config[:knife][:rackspace_metadata] = JSON.parse(m) },
        :default => ""
		
      option :ssh_network,
	    :short => "-n NETWORK",
	    :long => "--network NETWORK",
	    :description => "Choose private or public network of server for bootstrap to connect to; default is 'public'",
	    :proc => Proc.new { |n| Chef::Config[:knife][:ssh_network] = n },
	    :default => "public"

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

        server = connection.servers.create(
          :name => config[:server_name],
          :image_id => Chef::Config[:knife][:image],
          :flavor_id => locate_config_value(:flavor),
          :metadata => Chef::Config[:knife][:rackspace_metadata]
        )

        puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Host ID", :cyan)}: #{server.host_id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Flavor", :cyan)}: #{server.flavor.name}"
        puts "#{ui.color("Image", :cyan)}: #{server.image.name}"
        puts "#{ui.color("Metadata", :cyan)}: #{server.metadata}"

        print "\n#{ui.color("Waiting server", :magenta)}"

        # wait for it to be ready to do stuff
        server.wait_for { print "."; ready? }

        puts("\n")

        puts "#{ui.color("Public DNS Name", :cyan)}: #{public_dns_name(server)}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.addresses["public"][0]}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{server.addresses["private"][0]}"
        puts "#{ui.color("Password", :cyan)}: #{server.password}"

        print "\n#{ui.color("Waiting for sshd", :magenta)}"

        if Chef::Config[:knife][:ssh_network] == "private"
           print(".") until tcp_test_ssh(server.addresses["private"][0]) { sleep @initial_sleep_delay ||= 10; puts("done") }	
        else
           print(".") until tcp_test_ssh(server.addresses["public"][0]) { sleep @initial_sleep_delay ||= 10; puts("done") }
        end

        bootstrap_for_node(server).run

        puts "\n"
        puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Host ID", :cyan)}: #{server.host_id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Flavor", :cyan)}: #{server.flavor.name}"
        puts "#{ui.color("Image", :cyan)}: #{server.image.name}"
        puts "#{ui.color("Metadata", :cyan)}: #{server.metadata}"
        puts "#{ui.color("Public DNS Name", :cyan)}: #{public_dns_name(server)}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.addresses["public"][0]}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{server.addresses["private"][0]}"
        puts "#{ui.color("Password", :cyan)}: #{server.password}"
        puts "#{ui.color("Environment", :cyan)}: #{config[:environment] || '_default'}"
        puts "#{ui.color("Run List", :cyan)}: #{config[:run_list].join(', ')}"
      end

      def bootstrap_for_node(server)
        bootstrap = Chef::Knife::Bootstrap.new
        
        if Chef::Config[:knife][:ssh_network] == "private"  
            bootstrap.name_args = [private_ip_addr(server)]
        else
            bootstrap.name_args = [public_dns_name(server)]
        end
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:ssh_user] = config[:ssh_user] || "root"
        bootstrap.config[:ssh_password] = server.password
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.id
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        bootstrap
      end

    end
  end
end
