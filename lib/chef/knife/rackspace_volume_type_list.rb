#
# Author:: Mike Gunderloy (<MikeG1@larkfarm.com>)
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
    class RackspaceVolumeTypeList < Knife

      include Knife::RackspaceBase

      banner "knife rackspace volume_type list (options)"

      def run
        volume_type_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold)
        ]

        block_storage_connection.volume_types.sort_by(&:name).each do |volume_type|
          volume_type_list << volume_type.id.to_s
          volume_type_list << volume_type.name
        end

        puts ui.list(volume_type_list, :uneven_columns_across, 2)
      end
    end
  end
end