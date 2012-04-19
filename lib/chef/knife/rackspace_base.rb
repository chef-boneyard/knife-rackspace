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
    module RackspaceBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'net/ssh/multi'
            require 'readline'
            require 'chef/json_compat'
          end

          option :rackspace_api_key,
            :short => "-K KEY",
            :long => "--rackspace-api-key KEY",
            :description => "Your rackspace API key",
            :proc => Proc.new { |key| Chef::Config[:knife][:rackspace_api_key] = key }

          option :rackspace_username,
            :short => "-A USERNAME",
            :long => "--rackspace-username USERNAME",
            :description => "Your rackspace API username",
            :proc => Proc.new { |username| Chef::Config[:knife][:rackspace_username] = username }

          option :rackspace_api_auth_url,
            :long => "--rackspace-api-auth-url URL",
            :description => "Your rackspace API auth url",
            :default => "auth.api.rackspacecloud.com",
            :proc => Proc.new { |url| Chef::Config[:knife][:rackspace_api_auth_url] = url }
        end
      end

      def connection
        @connection ||= begin
          connection = Fog::Compute.new(
            :provider => 'Rackspace',
            :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
            :rackspace_username => (Chef::Config[:knife][:rackspace_username] || Chef::Config[:knife][:rackspace_api_username]),
            :rackspace_auth_url => Chef::Config[:knife][:rackspace_api_auth_url] || config[:rackspace_api_auth_url]
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

      def private_ip_addr(server)
        @private_ip_addr ||= begin
          server.addresses["private"][0]
        end	  
      end
	  
      def public_dns_name(server)
        @public_dns_name ||= begin
          Resolv.getname(server.addresses["public"][0])
        rescue
          "#{server.addresses["public"][0].gsub('.','-')}.static.cloud-ips.com"
        end
      end
    end
  end
end
