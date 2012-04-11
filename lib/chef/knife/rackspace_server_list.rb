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
    class RackspaceServerList < Knife

      include Knife::RackspaceBase

      banner "knife rackspace server list (options)"

      def run
        $stdout.sync = true

        server_list = [
          ui.color('Instance ID', :bold),
          ui.color('Public IP', :bold),
          ui.color('Private IP', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
          ui.color('Name', :bold),
          ui.color('State', :bold)
        ]
        connection.servers.all.each do |server|
          server_list << server.id.to_s
          server_list << (server.public_ip_address == nil ? "" : server.public_ip_address)
          server_list << (server.addresses["private"].first == nil ? "" : server.addresses["private"].first)
          server_list << (server.flavor_id == nil ? "" : server.flavor_id.to_s)
          server_list << (server.image_id == nil ? "" : server.image_id.to_s)
          server_list << server.name
          server_list << begin
            case server.state.downcase
            when 'deleted','suspended'
              ui.color(server.state.downcase, :red)
            when 'build'
              ui.color(server.state.downcase, :yellow)
            else
              ui.color(server.state.downcase, :green)
            end
          end
        end
        puts ui.list(server_list, :uneven_columns_across, 7)

      end
    end
  end
end
