# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io Web Application Scanning (WAS) endpoints.
    class WebAppScans < Base
      TERMINAL_STATUSES = %w[completed failed cancelled error].freeze

      # Supported scan export formats and their MIME types.
      FORMAT_CONTENT_TYPES = {
        'json' => 'application/json',
        'csv' => 'text/csv',
        'xml' => 'application/xml',
        'html' => 'text/html',
        'pdf' => 'application/pdf'
      }.freeze

      # Supported scan export formats.
      SUPPORTED_EXPORT_FORMATS = FORMAT_CONTENT_TYPES.keys.freeze

      # @return [Integer] default seconds between status polls
      DEFAULT_POLL_INTERVAL = 2

      # @return [Integer] default seconds between export status polls
      DEFAULT_EXPORT_POLL_INTERVAL = 5

      # @return [Integer] default timeout in seconds for waiting on scan completion
      DEFAULT_SCAN_TIMEOUT = 3600

      # @return [Integer] default timeout in seconds for waiting on export completion
      DEFAULT_EXPORT_TIMEOUT = 600

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

      # @param config_id [String] the scan configuration ID
      # @return [Hash] the configuration data
      def get_config(config_id)
        validate_path_segment!(config_id, name: 'config_id')
        get("/was/v2/configs/#{config_id}")
      end

      # @param config_id [String] the scan configuration ID
      # @param params [Hash] configuration parameters to update
      # @return [Hash] the updated configuration data
      def update_config(config_id, params)
        validate_path_segment!(config_id, name: 'config_id')
        put("/was/v2/configs/#{config_id}", params)
      end

      # @param config_id [String] the scan configuration ID
      # @return [Hash, nil] parsed response or nil
      def delete_config(config_id)
        validate_path_segment!(config_id, name: 'config_id')
        delete("/was/v2/configs/#{config_id}")
      end

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
        validate_path_segment!(config_id, name: 'config_id')
        post("/was/v2/configs/#{config_id}/scans")
      end

      # Retrieves the status of a specific scan.
      #
      # @param config_id [String] the scan configuration ID
      # @param scan_id [String] the scan ID
      # @return [Hash] scan status data
      def status(config_id, scan_id)
        validate_path_segment!(config_id, name: 'config_id')
        validate_path_segment!(scan_id, name: 'scan_id')
        get("/was/v2/configs/#{config_id}/scans/#{scan_id}")
      end

      # Searches vulnerabilities for a specific scan.
      #
      # @param scan_id [String] the scan ID
      # @param params [Hash] search parameters
      # @return [Hash] search results with vulnerabilities and pagination
      #
      # @example
      #   client.web_app_scans.search_scan_vulnerabilities(scan_id, severity: "high")
      def search_scan_vulnerabilities(scan_id, **params)
        validate_path_segment!(scan_id, name: 'scan_id')
        post("/was/v2/scans/#{scan_id}/vulnerabilities/search", params)
      end

      # Polls until the scan reaches a terminal status.
      #
      # @param config_id [String] the scan configuration ID
      # @param scan_id [String] the scan ID
      # @param timeout [Integer] maximum seconds to wait (default: 3600)
      # @param poll_interval [Integer] seconds between status checks (default: 2)
      # @return [Hash] the final scan status data
      # @raise [Tenable::TimeoutError] if the scan does not complete within the timeout
      def wait_until_complete(config_id, scan_id, timeout: DEFAULT_SCAN_TIMEOUT, poll_interval: DEFAULT_POLL_INTERVAL)
        validate_path_segment!(config_id, name: 'config_id')
        validate_path_segment!(scan_id, name: 'scan_id')
        poll_until(timeout: timeout, poll_interval: poll_interval, label: "WAS scan #{scan_id}") do
          result = status(config_id, scan_id)
          result if TERMINAL_STATUSES.include?(result['status'])
        end
      end

      # Retrieves details of a specific WAS scan.
      #
      # @param scan_id [String] the scan ID
      # @return [Hash] scan details
      def get_scan(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        get("/was/v2/scans/#{scan_id}")
      end

      # Stops a running WAS scan.
      #
      # @param scan_id [String] the scan ID
      # @return [Hash] the updated scan status
      def stop_scan(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        patch("/was/v2/scans/#{scan_id}", { 'requested_action' => 'stop' })
      end

      # Deletes a WAS scan.
      #
      # @param scan_id [String] the scan ID
      # @return [Hash, nil] parsed response or nil
      def delete_scan(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        delete("/was/v2/scans/#{scan_id}")
      end

      # Searches scans for a specific configuration.
      #
      # @param config_id [String] the scan configuration ID
      # @param params [Hash] search parameters
      # @return [Hash] search results with items and pagination
      def search_scans(config_id, **params)
        validate_path_segment!(config_id, name: 'config_id')
        post("/was/v2/configs/#{config_id}/scans/search", params)
      end

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
        validate_path_segment!(vuln_id, name: 'vuln_id')
        get("/was/v2/vulnerabilities/#{vuln_id}")
      end

      # Initiates a report export for a specific WAS scan.
      #
      # The format is specified via the Content-Type header per the Tenable API.
      #
      # @param scan_id [String] the scan ID
      # @param format [String] export format — one of "json", "csv", "xml", "html", or "pdf"
      # @return [Hash] export initiation response
      # @raise [ArgumentError] if the format is not supported
      def export_scan(scan_id, format:)
        validate_path_segment!(scan_id, name: 'scan_id')
        content_type = validate_export_format!(format)
        response = @connection.faraday.put("/was/v2/scans/#{scan_id}/report") do |req|
          req.headers['Content-Type'] = content_type
        end
        handle_response(response)
      end

      # Checks the status of a WAS scan report by attempting to fetch it.
      #
      # The WAS report API has no separate status endpoint. A 404 response
      # indicates the report is still being generated.
      #
      # @param scan_id [String] the scan ID
      # @param format [String] export format — one of "json", "csv", "xml", "html", or "pdf"
      # @return [Hash] status data with +"status"+ key ("ready" or "loading")
      def export_scan_status(scan_id, format:)
        validate_path_segment!(scan_id, name: 'scan_id')
        content_type = validate_export_format!(format)
        response = @connection.faraday.get("/was/v2/scans/#{scan_id}/report") do |req|
          req.headers['Accept'] = content_type
          req.headers['Content-Type'] = content_type
        end
        if response.status == 404
          { 'status' => 'loading' }
        else
          raise_for_status(response)
          { 'status' => 'ready' }
        end
      end

      # Downloads a completed WAS scan export as raw binary data.
      #
      # @param scan_id [String] the scan ID
      # @param format [String] export format — one of "json", "csv", "xml", "html", or "pdf"
      # @return [String] raw binary content of the export
      def download_scan_export(scan_id, format:)
        validate_path_segment!(scan_id, name: 'scan_id')
        content_type = validate_export_format!(format)
        response = @connection.faraday.get("/was/v2/scans/#{scan_id}/report") do |req|
          req.headers['Accept'] = content_type
          req.headers['Content-Type'] = content_type
        end
        raise_for_status(response)
        response.body
      end

      # Polls until a WAS scan export is ready for download.
      #
      # @param scan_id [String] the scan ID
      # @param format [String] export format — one of "json", "csv", "xml", "html", or "pdf"
      # @param timeout [Integer] maximum seconds to wait (default: 600)
      # @param poll_interval [Integer] seconds between status checks (default: 5)
      # @return [Hash] the final status data when export is ready
      # @raise [Tenable::TimeoutError] if the export does not become ready within the timeout
      def wait_for_scan_export(scan_id, format:, timeout: DEFAULT_EXPORT_TIMEOUT,
                               poll_interval: DEFAULT_EXPORT_POLL_INTERVAL)
        validate_path_segment!(scan_id, name: 'scan_id')
        poll_until(timeout: timeout, poll_interval: poll_interval, label: "WAS scan export for #{scan_id}") do
          status_data = export_scan_status(scan_id, format: format)
          status_data if status_data['status'] == 'ready'
        end
      end

      # Convenience method: requests an export, waits for completion, and downloads the result.
      #
      # @param scan_id [String] the scan ID
      # @param format [String] export format — one of "json", "csv", "xml", "html", or "pdf"
      # @param save_path [String, nil] if provided, writes binary content to this file path.
      #   The caller is responsible for ensuring the path is safe and writable.
      #   This value is used as-is with +File.binwrite+ — no sanitization is performed.
      # @param timeout [Integer] maximum seconds to wait (default: 600)
      # @param poll_interval [Integer] seconds between status checks (default: 5)
      # @return [String] the save_path if given, otherwise the raw binary content
      #
      # @example Download PDF to disk
      #   client.web_app_scans.export('scan-123', format: 'pdf', save_path: '/tmp/report.pdf')
      #
      # @example Get raw binary content
      #   binary = client.web_app_scans.export('scan-123', format: 'csv')
      def export(scan_id, format:, save_path: nil, timeout: DEFAULT_EXPORT_TIMEOUT,
                 poll_interval: DEFAULT_EXPORT_POLL_INTERVAL)
        validate_path_segment!(scan_id, name: 'scan_id')
        export_scan(scan_id, format: format)
        wait_for_scan_export(scan_id, format: format, timeout: timeout, poll_interval: poll_interval)
        content = download_scan_export(scan_id, format: format)

        if save_path
          File.binwrite(save_path, content)
          save_path
        else
          content
        end
      end

      # Initiates a bulk WAS findings export.
      #
      # @param body [Hash] export request parameters
      # @return [Hash] response containing the export UUID
      def export_findings(body = {})
        post('/was/v1/export/vulns', body)
      end

      # Retrieves the status of a WAS findings export.
      #
      # @param export_uuid [String] the export UUID
      # @return [Hash] status data
      def export_findings_status(export_uuid)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        get("/was/v1/export/vulns/#{export_uuid}/status")
      end

      # Downloads a single chunk of WAS findings export data.
      #
      # @param export_uuid [String] the export UUID
      # @param chunk_id [Integer] the chunk identifier
      # @return [Array<Hash>] array of finding records
      def export_findings_chunk(export_uuid, chunk_id)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        validate_path_segment!(chunk_id, name: 'chunk_id')
        get("/was/v1/export/vulns/#{export_uuid}/chunks/#{chunk_id}")
      end

      # Cancels an in-progress WAS findings export.
      #
      # @param export_uuid [String] the export UUID
      # @return [Hash] cancellation response
      def export_findings_cancel(export_uuid)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        post("/was/v1/export/vulns/#{export_uuid}/cancel")
      end

      private

      def validate_export_format!(format)
        FORMAT_CONTENT_TYPES.fetch(format) do
          raise ArgumentError, "Unsupported format '#{format}'. Must be one of: #{SUPPORTED_EXPORT_FORMATS.join(', ')}"
        end
      end
    end
  end
end
