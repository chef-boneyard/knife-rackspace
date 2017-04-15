#
# Author:: Denis Corol (<dcorol@paypal.com>)
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
    class RackspaceServerReboot < Knife

      include Knife::RackspaceBase
      
      banner "knife rackspace server reboot SERVER_ID [SERVER_ID] (options)"

      attr_accessor :initial_sleep_delay

      option :hard_reboot,
             :long => "--hard",
             :description => "Hard type of reboot",
             :boolean => true,
             :default => false

      option :soft_reboot,
             :long => "--soft",
             :description => "Soft type of reboot (Default)",
             :boolean => true,
             :default => false

      def run

        $stdout.sync = true

        reboot_type = config[:hard_reboot] ? "HARD" : "SOFT"

        if @name_args.empty?
          show_usage
          ui.fatal("You must specify a SERVER_ID")
          exit 1
        else
          @name_args.each do |instance_id|
            begin
              server = connection.servers.get(instance_id)
              msg_pair("Instance ID", server.id.to_s)
              msg_pair("Host ID", server.host_id)
              msg_pair("Name", server.name)
              msg_pair("Flavor", server.flavor.name)
              msg_pair("Image", server.image.name)
              msg_pair("Public IP Address", public_ip(server))
              msg_pair("Private IP Address", private_ip(server))
              msg_pair("Type of reboot", reboot_type.capitalize, :red)

              puts "\n"
              confirm("Do you really want to reboot this server")

              server.reboot("#{reboot_type}")

              ui.warn("Hard-reboot server: #{instance_id}") if reboot_type == "HARD"
              ui.warn("Rebooting server, please wait...")
              server.wait_for { sleep(2); print "."; ready? }
              ui.info(" Done")

            rescue NoMethodError
              ui.error("Could not locate server '#{instance_id}'.")
            end
          end
        end

      end

    end
  end
end