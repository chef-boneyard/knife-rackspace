#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require 'fog'
require 'chef/knife'
require 'chef/json_compat'

class Chef
  class Knife
    class RackspaceFlavorList < Knife

      banner "knife rackspace flavor list (options)"

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'

        connection = Fog::Compute.new(
          :provider => 'Rackspace',
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => Chef::Config[:knife][:rackspace_api_username] 
        )

        flavor_list = [ h.color('ID', :bold), h.color('Name', :bold), h.color('Architecture', :bold), h.color('RAM', :bold), h.color('Disk', :bold) , h.color('Cores', :bold) ]
        connection.flavors.sort_by(&:id).each do |flavor|
          flavor_list << flavor.id.to_s
          flavor_list << flavor.name
          flavor_list << "#{flavor.bits.to_s}-bit"
          flavor_list << "#{flavor.ram.to_s}"
          flavor_list << "#{flavor.disk.to_s} GB"
          flavor_list << flavor.cores.to_s
        end
        puts h.list(flavor_list, :columns_across, 6)
      end
    end
  end
end
