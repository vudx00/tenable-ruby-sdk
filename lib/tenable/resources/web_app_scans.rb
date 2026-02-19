# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io Web Application Scanning (WAS) endpoints.
    class WebAppScans < Base
      TERMINAL_STATUSES = %w[completed failed cancelled error].freeze

      # @return [Integer] default seconds between status polls
      DEFAULT_POLL_INTERVAL = 2

      # Creates a new web application scan configuration.
      #
      # @param name [String] name for the scan configuration
      # @param target [String] the target URL to scan
      # @return [Hash] the created configuration data
      # @raise [ApiError] on non-2xx responses
      #
      # @example
      #   client.web_app_scans.create_config(name: "My App", target: "https://example.com")
      def create_config(name:, target:)
        post('/was/v2/configs', { 'name' => name, 'target' => target })
      end

      # Launches a scan for the given configuration.
      #
      # @param config_id [String] the scan configuration ID
      # @return [Hash] response containing the scan ID
      def launch(config_id)
        post("/was/v2/configs/#{config_id}/scans")
      end

      # Retrieves the status of a specific scan.
      #
      # @param config_id [String] the scan configuration ID
      # @param scan_id [String] the scan ID
      # @return [Hash] scan status data
      def status(config_id, scan_id)
        get("/was/v2/configs/#{config_id}/scans/#{scan_id}")
      end

      # Retrieves findings for a scan configuration.
      #
      # @param config_id [String] the scan configuration ID
      # @param params [Hash] optional query parameters for filtering
      # @return [Hash] findings data
      #
      # @example
      #   client.web_app_scans.findings(config_id, severity: "high")
      def findings(config_id, **params)
        get("/was/v2/configs/#{config_id}/findings", params)
      end

      # Polls until the scan reaches a terminal status.
      #
      # @param config_id [String] the scan configuration ID
      # @param scan_id [String] the scan ID
      # @param poll_interval [Integer] seconds between status checks (default: 2)
      # @return [Hash] the final scan status data
      def wait_until_complete(config_id, scan_id, poll_interval: DEFAULT_POLL_INTERVAL)
        loop do
          result = status(config_id, scan_id)
          return result if TERMINAL_STATUSES.include?(result['status'])

          sleep(poll_interval)
        end
      end
    end
  end
end
