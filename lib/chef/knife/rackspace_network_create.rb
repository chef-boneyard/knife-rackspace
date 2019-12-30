require_relative "rackspace_base"

class Chef
  class Knife
    class RackspaceNetworkCreate < Knife

      include Knife::RackspaceBase

      banner "knife rackspace network create (options)"

      option :label,
        short: "-L LABEL",
        long: "--label LABEL",
        description: "Label for the network",
        required: true

      option :cidr,
        short: "-C CIDR",
        long: "--cidr CIDR",
        description: "CIDR for the network",
        required: true

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
        options = {}
        %i{cidr label}.each do |key|
          options[key] = config[key]
        end
        net = connection.networks.create(options)

        msg_pair("Network ID", net.id)
        msg_pair("Label", net.label)
        msg_pair("CIDR", net.cidr)
      end
    end
  end
end
