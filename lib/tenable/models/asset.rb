# frozen_string_literal: true

module Tenable
  module Models
    class Asset
      attr_reader :uuid, :hostname, :ipv4, :operating_system, :fqdn, :netbios_name

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
