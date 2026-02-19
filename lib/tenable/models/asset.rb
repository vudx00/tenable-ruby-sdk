# frozen_string_literal: true

module Tenable
  module Models
    # Represents an asset (host/device) from the Tenable.io API.
    class Asset
      # @return [String, nil] the asset UUID
      attr_reader :uuid

      # @return [String, nil] the hostname
      attr_reader :hostname

      # @return [String, nil] the IPv4 address
      attr_reader :ipv4

      # @return [Array<String>] operating systems detected on the asset
      attr_reader :operating_system

      # @return [Array<String>] fully qualified domain names
      attr_reader :fqdn

      # @return [String, nil] the NetBIOS name
      attr_reader :netbios_name

      # @param data [Hash] raw API response hash
      def initialize(data)
        @uuid = data['uuid']
        @hostname = data['hostname']
        @ipv4 = data['ipv4']
        @operating_system = data['operating_system'] || []
        @fqdn = data['fqdn'] || []
        @netbios_name = data['netbios_name']
      end
    end
  end
end
