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
    class RackspaceServerList < Knife

      deps do
        require 'fog'
        require 'chef/json_compat'
      end

      banner "knife rackspace server list (options)"

      option :rackspace_api_key,
        :short => "-K KEY",
        :long => "--rackspace-api-key KEY",
        :description => "Your rackspace API key",
        :proc => Proc.new { |key| Chef::Config[:knife][:rackspace_api_key] = key }

      option :rackspace_api_username,
        :short => "-A USERNAME",
        :long => "--rackspace-api-username USERNAME",
        :description => "Your rackspace API username",
        :proc => Proc.new { |username| Chef::Config[:knife][:rackspace_api_username] = username }

      option :rackspace_api_auth_url,
        :long => "--rackspace-api-auth-url URL",
        :description => "Your rackspace API auth url",
        :default => "auth.api.rackspacecloud.com",
        :proc => Proc.new { |url| Chef::Config[:knife][:rackspace_api_auth_url] = url }

      def run
        $stdout.sync = true
        
        connection = Fog::Compute.new(
          :provider => 'Rackspace',
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => Chef::Config[:knife][:rackspace_api_username],
          :rackspace_auth_url => Chef::Config[:knife][:rackspace_api_auth_url] || config[:rackspace_api_auth_url]
        )

        server_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
          ui.color('State', :bold)
        ]
        connection.servers.all.each do |server|
          server_list << server.id.to_s
          server_list << server.name
          server_list << server.addresses["public"][0]
          server_list << server.addresses["private"][0]
          server_list << server.flavor.name.split(/\s/).first
          server_list << server.image.name
          server_list << server.status.downcase
        end
        puts ui.list(server_list, :columns_across, 7)

      end
    end
  end
end
