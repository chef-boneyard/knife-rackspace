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

require 'chef/knife'

class Chef
  class Knife
    class RackspaceServerDelete < Knife
      
      deps do
        require 'fog'
        require 'chef/knife'
        require 'chef/json_compat'
        require 'resolv'
      end
      
      banner "knife rackspace server delete SERVER_ID (options)"

      option :rackspace_api_key,
        :short => "-K KEY",
        :long => "--rackspace-api-key KEY",
        :description => "Your rackspace API key",
        :proc => Proc.new { |key| Chef::Config[:knife][:rackspace_api_key] = key }

      option :rackspace_username,
        :short => "-A USERNAME",
        :long => "--rackspace-username USERNAME",
        :description => "Your rackspace API username",
        :proc => Proc.new { |username| Chef::Config[:knife][:rackspace_username] = username }

      option :rackspace_api_auth_url,
        :long => "--rackspace-api-auth-url URL",
        :description => "Your rackspace API auth url",
        :default => "auth.api.rackspacecloud.com",
        :proc => Proc.new { |url| Chef::Config[:knife][:rackspace_api_auth_url] = url }

      def run
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'

        connection = Fog::Compute.new(
          :provider => 'Rackspace',
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => (Chef::Config[:knife][:rackspace_username] || Chef::Config[:knife][:rackspace_api_username]),
          :rackspace_auth_url => Chef::Config[:knife][:rackspace_api_auth_url] || config[:rackspace_api_auth_url]
        )

        server = connection.servers.get(@name_args[0])

        puts "#{ui.color("Instance ID", :cyan)}: #{server.id}"
        puts "#{ui.color("Host ID", :cyan)}: #{server.host_id}"
        puts "#{ui.color("Name", :cyan)}: #{server.name}"
        puts "#{ui.color("Flavor", :cyan)}: #{server.flavor.name}"
        puts "#{ui.color("Image", :cyan)}: #{server.image.name}"
        puts "#{ui.color("Public DNS Name", :cyan)}: #{public_dns_name(server)}"
        puts "#{ui.color("Public IP Address", :cyan)}: #{server.addresses["public"][0]}"
        puts "#{ui.color("Private IP Address", :cyan)}: #{server.addresses["private"][0]}"

        puts "\n"
        confirm("Do you really want to delete this server")

        server.destroy

        ui.warn("Deleted server #{server.id} named #{server.name}")
      end

      def public_dns_name(server)
        @public_dns_name ||= begin
          Resolv.getname(server.addresses["public"][0])
        rescue
          "#{server.addresses["public"][0].gsub('.','-')}.static.cloud-ips.com"
        end
      end
    end
  end
end
