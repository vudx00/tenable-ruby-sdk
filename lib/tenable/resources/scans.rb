# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io scan management endpoints.
    class Scans < Base
      # Supported scan export formats.
      SUPPORTED_EXPORT_FORMATS = %w[pdf csv nessus].freeze

      # @return [Integer] default seconds between export status polls
      DEFAULT_EXPORT_POLL_INTERVAL = 5

      # @return [Integer] default timeout in seconds for waiting on export completion
      DEFAULT_EXPORT_TIMEOUT = 600

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

      # Retrieves full details of a scan including host and vulnerability info.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] detailed scan data
      def details(scan_id)
        get("/scans/#{scan_id}")
      end

      # Updates an existing scan configuration.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param params [Hash] scan configuration to update
      # @return [Hash] the updated scan data
      def update(scan_id, params)
        put("/scans/#{scan_id}", params)
      end

      # Deletes a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response or nil
      def destroy(scan_id)
        delete("/scans/#{scan_id}")
      end

      # Retrieves the latest status of a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] status data for the scan
      def status(scan_id)
        get("/scans/#{scan_id}/latest-status")
      end

      # Pauses a running scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response
      def pause(scan_id)
        post("/scans/#{scan_id}/pause")
      end

      # Resumes a paused scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response
      def resume(scan_id)
        post("/scans/#{scan_id}/resume")
      end

      # Stops a running scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response
      def stop(scan_id)
        post("/scans/#{scan_id}/stop")
      end

      # Copies a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] the copied scan data
      def copy(scan_id)
        post("/scans/#{scan_id}/copy")
      end

      # Updates the schedule for a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param params [Hash] schedule configuration
      # @return [Hash] the updated schedule data
      def schedule(scan_id, params)
        put("/scans/#{scan_id}/schedule", params)
      end

      # Retrieves the scan history.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] history data including an array of history records
      def history(scan_id)
        get("/scans/#{scan_id}/history")
      end

      # Retrieves details for a specific host within a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param host_id [Integer, String] the host ID
      # @return [Hash] host details including vulnerability info
      def host_details(scan_id, host_id)
        get("/scans/#{scan_id}/hosts/#{host_id}")
      end

      # Retrieves plugin output for a specific host and plugin within a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param host_id [Integer, String] the host ID
      # @param plugin_id [Integer, String] the plugin ID
      # @return [Hash] plugin output data
      def plugin_output(scan_id, host_id, plugin_id)
        get("/scans/#{scan_id}/hosts/#{host_id}/plugins/#{plugin_id}")
      end

      # Initiates a scan report export.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param format [String] export format — one of "pdf", "csv", or "nessus"
      # @param body [Hash] additional export parameters (e.g., +chapters+ for PDF)
      # @return [Hash] response containing the file ID under +"file"+ key
      # @raise [ArgumentError] if the format is not supported
      #
      # @example
      #   client.scans.export_request(123, format: 'pdf', chapters: 'vuln_hosts_summary')
      def export_request(scan_id, format:, **body)
        unless SUPPORTED_EXPORT_FORMATS.include?(format)
          raise ArgumentError, "Unsupported format '#{format}'. Must be one of: #{SUPPORTED_EXPORT_FORMATS.join(', ')}"
        end

        post("/scans/#{scan_id}/export", body.merge(format: format))
      end

      # Retrieves the status of a scan export.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param file_id [Integer, String] the export file ID
      # @return [Hash] status data with +"status"+ key ("ready" or "loading")
      def export_status(scan_id, file_id)
        get("/scans/#{scan_id}/export/#{file_id}/status")
      end

      # Downloads a completed scan export as raw binary data.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param file_id [Integer, String] the export file ID
      # @return [String] raw binary content of the export file
      def export_download(scan_id, file_id)
        get_raw("/scans/#{scan_id}/export/#{file_id}/download")
      end

      # Polls until a scan export is ready for download.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param file_id [Integer, String] the export file ID
      # @param timeout [Integer] maximum seconds to wait (default: 600)
      # @param poll_interval [Integer] seconds between status checks (default: 5)
      # @return [Hash] the final status data when export is ready
      # @raise [Tenable::TimeoutError] if the export does not become ready within the timeout
      def wait_for_export(scan_id, file_id, timeout: DEFAULT_EXPORT_TIMEOUT, poll_interval: DEFAULT_EXPORT_POLL_INTERVAL)
        deadline = Time.now + timeout
        loop do
          raise Tenable::TimeoutError, "Scan export #{file_id} timed out" if Time.now >= deadline

          status_data = export_status(scan_id, file_id)
          return status_data if status_data['status'] == 'ready'

          sleep(poll_interval)
        end
      end

      # Convenience method: requests an export, waits for completion, and downloads the result.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param format [String] export format — one of "pdf", "csv", or "nessus"
      # @param save_path [String, nil] if provided, writes binary content to this file path
      # @param timeout [Integer] maximum seconds to wait (default: 600)
      # @param poll_interval [Integer] seconds between status checks (default: 5)
      # @param body [Hash] additional export parameters
      # @return [String] the save_path if given, otherwise the raw binary content
      #
      # @example Download PDF to disk
      #   client.scans.export(123, format: 'pdf', save_path: '/tmp/report.pdf')
      #
      # @example Get raw binary content
      #   binary = client.scans.export(123, format: 'nessus')
      def export(scan_id, format:, save_path: nil, timeout: DEFAULT_EXPORT_TIMEOUT,
                 poll_interval: DEFAULT_EXPORT_POLL_INTERVAL, **body)
        result = export_request(scan_id, format: format, **body)
        file_id = result['file']
        wait_for_export(scan_id, file_id, timeout: timeout, poll_interval: poll_interval)
        content = export_download(scan_id, file_id)

        if save_path
          File.binwrite(save_path, content)
          save_path
        else
          content
        end
      end
    end
  end
end
