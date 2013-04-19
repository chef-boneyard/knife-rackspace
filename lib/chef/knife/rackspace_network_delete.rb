require 'chef/knife/rackspace_base'

class Chef
  class Knife
    class RackspaceNetworkDelete < Knife

      include Knife::RackspaceBase

      banner "knife rackspace network delete NETWORK_ID [NETWORK_ID] (options)"
      
      def run
        if version_one?
          ui.error "Networks are not supported in v1"
          exit 1
        else
          @name_args.each do |net_id|
            network = connection.networks.get(net_id)
            unless(network)
              ui.error "Could not locate network: #{net_id}"
              exit 1
            end
            msg_pair("Network ID", network.id)
            msg_pair("Label", network.label)
            msg_pair("CIDR", network.cidr)
            
            puts "\n"
            confirm("Do you really want to delete this network")

            network.destroy

            ui.warn("Deleted network #{network.id}")
          end
        end
      end
    end
  end
end
