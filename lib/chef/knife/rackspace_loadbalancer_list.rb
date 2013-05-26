require 'chef/knife'
require 'chef/knife/rackspace_loadbalancer_base'
require 'fog'

module RackspaceService
  class RackspaceLoadbalancerList < Chef::Knife
  	
  	include Chef::Knife::RackspaceLoadBalancerBase

    banner "knife rackspace loadbalancer list"

    def run
      load_balancer_list = [
        ui.color("Id", :bold),
        ui.color("Name", :bold),
        ui.color("Nodes", :bold),
        ui.color("Virtual IP", :bold),
        ui.color("Protocol / Port", :bold),
        ui.color("Algorithm", :bold),
        ui.color("Status", :bold)
      ]

      loadbalancers = connection.list_load_balancers.body["loadBalancers"]

      loadbalancers.each do |lb|
        vip = lb["virtualIps"].first

        load_balancer_list << lb["id"].to_s
        load_balancer_list << lb["name"]
        load_balancer_list << lb["nodeCount"].to_s
        load_balancer_list << (vip.nil? ? "None" : vip["address"])
        load_balancer_list << "#{lb["protocol"]} / #{lb["port"]}"
        load_balancer_list << lb["algorithm"]
        load_balancer_list << lb["status"]
      end

      puts ui.list(load_balancer_list, :uneven_columns_across, 7)
    end
  
  end
end