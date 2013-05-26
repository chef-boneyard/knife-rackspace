#
# Author:: Milos Gajdos (<milos@gocardless.com>)
# Copyright:: Copyright (c) 2013 GoCardless, Ltd.
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
require 'chef/knife/rackspace_loadbalancer_base'
require 'fog'

module RackspaceService
  class RackspaceLoadbalancerShow < Chef::Knife
  	
  	include Chef::Knife::RackspaceLoadBalancerBase

    banner "knife rackspace loadbalancer show ID"

    def run
      
      unless name_args.size == 1
        ui.fatal("You must provide Load Balancer ID !")
        show_usage
        exit 1
      end

      id = name_args.first
      loadbalancer = connection.get_load_balancer(id).body["loadBalancer"]

      node_properties = %w{address port type status condition}
      vip_properties  = %w{address type ipVersion}
      
      puts "#{ui.color("Name ", :cyan)}: #{loadbalancer["name"]}"
      puts "#{ui.color("ID ", :cyan)}: #{loadbalancer["id"]}"
      puts "#{ui.color("Protocol / Port ", :cyan)}: #{loadbalancer["protocol"]} / #{loadbalancer["port"]}"
      puts "#{ui.color("Public IP ", :cyan)}: #{loadbalancer["sourceAddresses"]["ipv4Public"]}"
      puts "#{ui.color("Private IP ", :cyan)}: #{loadbalancer["sourceAddresses"]["ipv4Servicenet"]}"
      puts "#{ui.color("Algorithm ", :cyan)}: #{loadbalancer["algorithm"]}"
      puts "#{ui.color("Status ", :cyan)}: #{loadbalancer["status"]}"
      puts "#{ui.color("Cluster ", :cyan)}: #{loadbalancer["cluster"]["name"]}"
      puts "#{ui.color("Timeout ", :cyan)}: #{loadbalancer["timeout"]}"
      puts "#{ui.color("Half Closed ", :cyan)}: #{loadbalancer["halfClosed"]}"
      puts "#{ui.color("Connection Logging ", :cyan)}: #{loadbalancer["connectionLogging"]["enabled"]}"
      puts "#{ui.color("Connection Caching ", :cyan)}: #{loadbalancer["contentCaching"]["enabled"]}"
      puts "#{ui.color("Created ", :cyan)}: #{loadbalancer["created"]["time"]}"
      puts "#{ui.color("updated ", :cyan)}: #{loadbalancer["updated"]["time"]}"
      puts "#{ui.color("= Nodes =", :red)} \n"
      print_rs_entity(loadbalancer["nodes"], node_properties) unless loadbalancer["nodes"].empty?
      puts "#{ui.color("= Virtual IPs =", :red)}: \n"
      print_rs_entity(loadbalancer["virtualIps"], vip_properties) unless loadbalancer["virtualIps"].empty?

    end

    def print_rs_entity(entity, properties)
      entity.each do |e|
        properties.each do |p|
          puts "#{ui.color("#{p.capitalize}", :cyan)}: #{e[p]}"
        end
      end
    end
  
  end
end