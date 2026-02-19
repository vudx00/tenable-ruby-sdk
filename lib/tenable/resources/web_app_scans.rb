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

      # Retrieves a scan configuration by ID.
      #
      # @param config_id [String] the scan configuration ID
      # @return [Hash] the configuration data
      def get_config(config_id)
        get("/was/v2/configs/#{config_id}")
      end

      # Updates a scan configuration.
      #
      # @param config_id [String] the scan configuration ID
      # @param params [Hash] configuration parameters to update
      # @return [Hash] the updated configuration data
      def update_config(config_id, params)
        put("/was/v2/configs/#{config_id}", params)
      end

      # Deletes a scan configuration.
      #
      # @param config_id [String] the scan configuration ID
      # @return [Hash, nil] parsed response or nil
      def delete_config(config_id)
        delete("/was/v2/configs/#{config_id}")
      end

      # Searches scan configurations.
      #
      # @param params [Hash] search parameters
      # @return [Hash] search results with items and pagination
      def search_configs(**params)
        post('/was/v2/configs/search', params)
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

      # Retrieves details of a specific WAS scan.
      #
      # @param scan_id [String] the scan ID
      # @return [Hash] scan details
      def get_scan(scan_id)
        get("/was/v2/scans/#{scan_id}")
      end

      # Stops a running WAS scan.
      #
      # @param scan_id [String] the scan ID
      # @return [Hash] the updated scan status
      def stop_scan(scan_id)
        patch("/was/v2/scans/#{scan_id}/status", { 'status' => 'stopped' })
      end

      # Deletes a WAS scan.
      #
      # @param scan_id [String] the scan ID
      # @return [Hash, nil] parsed response or nil
      def delete_scan(scan_id)
        delete("/was/v2/scans/#{scan_id}")
      end

      # Searches WAS scans.
      #
      # @param params [Hash] search parameters
      # @return [Hash] search results with items and pagination
      def search_scans(**params)
        post('/was/v2/scans/search', params)
      end

      # Searches WAS vulnerabilities.
      #
      # @param params [Hash] search parameters
      # @return [Hash] search results with items and pagination
      def search_vulnerabilities(**params)
        post('/was/v2/vulnerabilities/search', params)
      end

      # Retrieves details for a specific WAS vulnerability.
      #
      # @param vuln_id [String] the vulnerability ID
      # @return [Hash] vulnerability details
      def vulnerability_details(vuln_id)
        get("/was/v2/vulns/#{vuln_id}")
      end
    end
  end
end
