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

require 'chef/knife/rackspace_base'

class Chef
  class Knife
    class RackspaceImageList < Knife

      include Knife::RackspaceBase

      banner "knife rackspace image list (options)"

      def run
        image_list = [
          ui.color('ID', :bold),
          ui.color('Name', :bold)
        ]

        connection.images.sort_by(&:name).each do |image|
          image_list << image.id.to_s
          image_list << image.name
        end

        puts ui.list(image_list, :uneven_columns_across, 2)
      end
    end
  end
end
