module VCR
  module Filters
    class Network
      def initialize(vcr_configuration)
        clear
        vcr_configuration.before_record do |interaction, cassette|
          detect(interaction, cassette)
        end
        vcr_configuration.before_record do |interaction, cassette|
          filter(interaction, cassette)
        end
      end

      def clear
        @networks = Set.new
      end

      def detect(interaction, cassette)
        if interaction.request.uri.match /os-networksv2/
          if interaction.request.uri =~ /os-networksv2\/([^\/]*)/
            @networks << $~[1]
          end

          if interaction.response.headers['Content-Type'].include? 'application/json'
            json = JSON.parse(interaction.response.body)
            capture_networks(json)
          end
        end
      end

      def filter(interaction, cassette)
        @networks.each_with_index do |network, index|
          interaction.filter!(network, "network_#{index}")
        end
      end

      private

      def capture_networks(json)
        if json['network']
          capture_network json['network']
        elsif json['networks']
          json['networks'].each { |network|
            capture_network network
          }
        end
      end

      def capture_network(network)
        @networks << network['id'] unless ['public', 'private'].include? network['label']
      end
    end
  end
end
