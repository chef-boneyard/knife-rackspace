require "chef/knife/rackspace_base"

class Chef
  class Knife
    class RackspaceNetworkList < Knife

      include Knife::RackspaceBase

      banner "knife rackspace network list (options)"

      def run
        if version_one?
          ui.error "Networks are not supported in v1"
          exit 1
        else
          networks_list = [
            ui.color("Label", :bold),
            ui.color("CIDR", :bold),
            ui.color("ID", :bold),
          ]
        end
        connection.networks.sort_by(&:id).each do |network|
          networks_list << network.label
          networks_list << network.cidr
          networks_list << network.id.to_s
        end
        puts ui.list(networks_list, :uneven_columns_across, 3)
      end
    end
  end
end
