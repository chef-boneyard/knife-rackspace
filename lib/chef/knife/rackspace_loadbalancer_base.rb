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

class Chef
  class Knife
    module RackspaceLoadBalancerBase

      def self.included(base)
        base.class_eval do

          deps do
            require 'readline'
            require 'fog'
          end

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

          option :rackspace_lb_endpoint,
            :short => "-E ENDPOINT",
            :long => "--rackspace-lb-endpoint ENDPOINT",
            :description => "Rackspace LoadBalancer service endpoint",
            :proc => Proc.new {|region| Chef::Config[:knife][:rackspace_lb_endpoint] = region}
        end
      end

      def connection
      	@connection ||= begin
          connection = Fog::Rackspace::LoadBalancers.new({
          	:rackspace_api_key     => Chef::Config[:knife][:rackspace_api_key]      || config[:rackspace_api_key],
          	:rackspace_username    => Chef::Config[:knife][:rackspace_api_username] || config[:rackspace_api_username],
          	:rackspace_auth_url    => Chef::Config[:knife][:rackspace_api_auth_url] || config[:rackspace_api_auth_url],
          	:rackspace_lb_endpoint => Chef::Config[:knife][:rackspace_lb_endpoint]  || config[:rackspace_lb_endpoint]
          })
      	end
      end

    end
  end
end