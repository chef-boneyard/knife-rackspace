#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Copyright:: Copyright (c) 2011-2013 Opscode, Inc.
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
require 'fog'

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
            :default => "v2",
            :proc => Proc.new { |version| Chef::Config[:knife][:rackspace_version] = version }

          option :rackspace_auth_url,
            :long => "--rackspace-auth-url URL",
            :description => "Your rackspace API auth url",
            :proc => Proc.new { |url| Chef::Config[:knife][:rackspace_auth_url] = url }

          option :rackspace_region,
            :long => "--rackspace-region REGION",
            :description => "Your rackspace region",
            :proc => Proc.new { |region| Chef::Config[:knife][:rackspace_region] = region }

          option :file,
            :long => '--file DESTINATION-PATH=SOURCE-PATH',
            :description => 'File to inject on node',
            :proc => Proc.new {|arg|
              Chef::Config[:knife][:file] ||= []
              Chef::Config[:knife][:file] << arg
            }
        end
      end

      def connection
        Chef::Log.debug("version #{Chef::Config[:knife][:rackspace_version]} (config)")
        Chef::Log.debug("version #{config[:rackspace_version]} (cli)")
        Chef::Log.debug("rackspace_api_key #{Chef::Config[:knife][:rackspace_api_key]}")
        Chef::Log.debug("rackspace_username #{Chef::Config[:knife][:rackspace_username]}")
        Chef::Log.debug("rackspace_api_username #{Chef::Config[:knife][:rackspace_api_username]}")
        Chef::Log.debug("rackspace_auth_url #{Chef::Config[:knife][:rackspace_auth_url]}")
        Chef::Log.debug("rackspace_auth_url #{config[:rackspace_api_auth_url]}")
        Chef::Log.debug("rackspace_auth_url #{auth_endpoint} (using)")
        Chef::Log.debug("rackspace_region #{Chef::Config[:knife][:rackspace_region]}")
        Chef::Log.debug("rackspace_region #{config[:rackspace_region]}")

        if version_one?
          Chef::Log.debug("rackspace v1")
          region_warning_for_v1
          @connection ||= begin
            connection = Fog::Compute.new(connection_params({
              :version => 'v1'
              }))
          end
        else
          Chef::Log.debug("rackspace v2")
          @connection ||= begin
            connection = Fog::Compute.new(connection_params({
              :version => 'v2'
            }))
          end
        end
      end

      def region_warning_for_v1
        if Chef::Config[:knife][:rackspace_region] || config[:rackspace_region]
          Chef::Log.warn("Ignoring the rackspace_region parameter as it is only supported for Next Gen Cloud Servers (v2)")
        end
      end

      def connection_params(options={})
        unless locate_config_value(:rackspace_region)
          ui.error "Please specify region via the command line using the --rackspace-region switch or add a knife[:rackspace_region] = REGION to your knife file."
          exit 1
        end

        hash = options.merge({
          :provider => 'Rackspace',
          :rackspace_api_key => Chef::Config[:knife][:rackspace_api_key],
          :rackspace_username => (Chef::Config[:knife][:rackspace_username] || Chef::Config[:knife][:rackspace_api_username]),
          :rackspace_auth_url => auth_endpoint,
          :rackspace_region => locate_config_value(:rackspace_region)
        })

        hash[:connection_options] ||= {}
        Chef::Log.debug("https_proxy #{ Chef::Config[:https_proxy] || "<not specified>"} (config)")
        Chef::Log.debug("http_proxy #{ Chef::Config[:http_proxy] || "<not specified>"} (config)")
        if Chef::Config.has_key?(:https_proxy) || Chef::Config.has_key?(:http_proxy)
          hash[:connection_options] = {:proxy => Chef::Config[:https_proxy] || Chef::Config[:http_proxy] }
        end
        Chef::Log.debug("using proxy #{hash[:connection_options][:proxy] || "<none>"} (config)")
        Chef::Log.debug("ssl_verify_peer #{Chef::Config[:knife].has_key?(:ssl_verify_peer) ? Chef::Config[:knife][:ssl_verify_peer] : "<not specified>"} (config)")
        hash[:connection_options][:ssl_verify_peer] = Chef::Config[:knife][:ssl_verify_peer] if Chef::Config[:knife].has_key?(:ssl_verify_peer)

        hash
      end

      def auth_endpoint
        url = locate_config_value(:rackspace_auth_url)
        return url if url
        (locate_config_value(:rackspace_region) == 'lon') ? ::Fog::Rackspace::UK_AUTH_ENDPOINT : ::Fog::Rackspace::US_AUTH_ENDPOINT
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def ip_address(server, network='public')
        if version_one?
          case network
          when 'public'; v1_public_ip(server)
          when 'private'; v1_private_ip(server)
          else raise NotImplementedError
          end
        else
          if network == 'public' && v2_access_ip(server) != ""
            v2_access_ip(server)
          else
            v2_ip_address(server, network)
          end
        end
      end

      def public_dns_name(server)
        if public_ip_address = ip_address(server, 'public')
          @public_dns_name ||= begin
            Resolv.getname(public_ip_address)
          rescue
            "#{public_ip_address}.xip.io"
          end
        end
      end

      private

      def version_one?
        rackspace_api_version == 'v1'
      end

      def rackspace_api_version
        version = locate_config_value(:rackspace_version) || 'v2'
        version.downcase
      end

      def v1_public_ip(server)
          server.public_ip_address == nil ? "" : server.public_ip_address
      end

      def v1_private_ip(server)
        server.addresses["private"].first == nil ? "" : server.addresses["private"].first
      end

      def v2_ip_address(server, network)
        network_ips = server.addresses[network]
        extract_ipv4_address(network_ips) if network_ips
      end

      def v2_access_ip(server)
        server.access_ipv4_address == nil ? "" : server.access_ipv4_address
      end

      def extract_ipv4_address(ip_addresses)
        address = ip_addresses.select { |ip| ip["version"] == 4 }.first
        address ? address["addr"] : ""
      end
    end
  end
end
