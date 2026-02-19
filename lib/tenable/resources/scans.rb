# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io scan management endpoints.
    class Scans < Base
      # Lists all scans.
      #
      # @return [Hash] parsed response containing scan list under +"scans"+ key
      #
      # @example
      #   client.scans.list
      def list
        get('/scans')
      end

      # Creates a new scan.
      #
      # @param params [Hash] scan configuration (e.g., +uuid+, +settings+)
      # @return [Hash] the created scan data
      # @raise [ApiError] on non-2xx responses
      #
      # @example
      #   client.scans.create(uuid: template_uuid, settings: { name: "My Scan", text_targets: "10.0.0.1" })
      def create(params)
        post('/scans', params)
      end

      # Launches an existing scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] response containing the scan instance UUID
      def launch(scan_id)
        post("/scans/#{scan_id}/launch")
      end

      # Retrieves the latest status of a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] status data for the scan
      def status(scan_id)
        get("/scans/#{scan_id}/latest-status")
      end
    end
  end
end
