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

          option :rackspace_version,
            :long => '--rackspace-version VERSION',
            :description => 'Rackspace Cloud Servers API version',
            :default => "v1",
            :proc => Proc.new { |version| Chef::Config[:knife][:rackspace_version] = version }

          option :rackspace_api_auth_url,
            :long => "--rackspace-api-auth-url URL",
            :description => "Your rackspace API auth url",
            :default => "auth.api.rackspacecloud.com",
            :proc => Proc.new { |url| Chef::Config[:knife][:rackspace_api_auth_url] = url }

          option :rackspace_endpoint,
            :long => "--rackspace-endpoint URL",
            :description => "Your rackspace API endpoint",
            :default => "https://dfw.servers.api.rackspacecloud.com/v2",
            :proc => Proc.new { |url| Chef::Config[:knife][:rackspace_endpoint] = url }
        end
      end

      def connection
        @connection ||= begin
          connection = Fog::Compute.new(
            :provider => 'Rackspace',
            :version => Chef::Config[:knife][:rackspace_version],
            :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
            :rackspace_username => (Chef::Config[:knife][:rackspace_username] || Chef::Config[:knife][:rackspace_api_username]),
            :rackspace_auth_url => Chef::Config[:knife][:rackspace_api_auth_url] || config[:rackspace_api_auth_url],
            :rackspace_endpoint => Chef::Config[:knife][:rackspace_endpoint] || config[:rackspace_endpoint]
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def public_ip(server)
        if version_one?
          v1_public_ip(server)
        else
          v2_public_ip(server)
        end
      end

      def private_ip(server)
        if version_one?
          v1_private_ip(server)
        else
          v2_private_ip(server)
        end
      end

      def public_dns_name(server)
        ip_address = public_ip(server)

        @public_dns_name ||= begin
          Resolv.getname(ip_address)
        rescue
          "#{ip_address.gsub('.','-')}.static.cloud-ips.com"
        end
      end

      private

      def version_one?
        rackspace_api_version == 'v1'
      end

      def rackspace_api_version
        version = Chef::Config[:knife][:rackspace_version] || 'v1'
        version.downcase
      end

      def v1_public_ip(server)
          server.public_ip_address == nil ? "" : server.public_ip_address
      end

      def v1_private_ip(server)
        server.addresses["private"].first == nil ? "" : server.addresses["private"].first
      end

      def v2_public_ip(server)
        public_ips = server.addresses["public"]
        extract_ipv4_address(public_ips)
      end

      def v2_private_ip(server)
        private_ips = server.addresses["private"]
        extract_ipv4_address(private_ips)
      end

      def extract_ipv4_address(ip_addresses)
        address = ip_addresses.select { |ip| ip["version"] == 4 }.first
        address ? address["addr"] : ""
      end
    end
  end
end


