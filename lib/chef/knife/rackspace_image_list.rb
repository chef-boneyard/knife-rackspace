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

require 'chef/knife'

class Chef
  class Knife
    class RackspaceImageList < Knife

      deps do
        require 'fog'
        require 'chef/json_compat'
      end

      banner "knife rackspace image list (options)"

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
        connection = Fog::Compute.new(
          :provider => 'Rackspace',
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => Chef::Config[:knife][:rackspace_api_username],
          :rackspace_auth_url => Chef::Config[:knife][:rackspace_api_auth_url] || config[:rackspace_api_auth_url]
        )

        image_list = [ ui.color('ID', :bold), ui.color('Name', :bold) ]
        connection.images.sort_by(&:name).each do |image|
          image_list << image.id.to_s
          image_list << image.name
        end
        puts ui.list(image_list, :columns_across, 2)
      end
    end
  end
end
