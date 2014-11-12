#
# Author:: Carlos Diaz (<crdiaz324@gmail.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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
    class RackspaceCbsVolumeList < Knife

      include Knife::RackspaceBase

      banner "knife rackspace cbs_volume list"

      def run
        cbs_volume_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold),
          ui.color('Volume Size', :bold),
          ui.color('Volume Type', :bold)
        ]

        block_storage_connection.volumes.sort_by(&:display_name).each do |volume|
          cbs_volume_list << volume.id.to_s
          cbs_volume_list << volume.display_name
          cbs_volume_list << volume.size.to_s
          cbs_volume_list << volume.volume_type
        end

        puts ui.list(cbs_volume_list, :uneven_columns_across, 4)
      end
    end
  end
end