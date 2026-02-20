# frozen_string_literal: true

module Tenable
  module Models
    # Represents an asset (host/device) from the Tenable.io API.
    Asset = Data.define(:uuid, :hostname, :ipv4, :operating_system, :fqdn, :netbios_name) do
      # Builds an Asset from a raw API response hash.
      #
      # @param data [Hash] raw API response hash with string keys
      # @return [Asset]
      def self.from_api(data)
        data = data.transform_keys(&:to_sym)
        new(
          uuid: data[:uuid],
          hostname: data[:hostname],
          ipv4: data[:ipv4],
          operating_system: data[:operating_system] || [],
          fqdn: data[:fqdn] || [],
          netbios_name: data[:netbios_name]
        )
      end
    end
  end
end
