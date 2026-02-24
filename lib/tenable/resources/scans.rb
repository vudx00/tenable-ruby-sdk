# frozen_string_literal: true

require 'uri'

module Tenable
  module Resources
    # Provides access to the Tenable.io scan management endpoints.
    class Scans < Base
      # Supported scan export formats.
      SUPPORTED_EXPORT_FORMATS = %w[nessus html pdf csv db].freeze

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
        validate_path_segment!(scan_id, name: 'scan_id')
        post("/scans/#{scan_id}/launch")
      end

      # Retrieves full details of a scan including host and vulnerability info.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] detailed scan data
      def details(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        get("/scans/#{scan_id}")
      end

      # Updates an existing scan configuration.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param params [Hash] scan configuration to update
      # @return [Hash] the updated scan data
      def update(scan_id, params)
        validate_path_segment!(scan_id, name: 'scan_id')
        put("/scans/#{scan_id}", params)
      end

      # Deletes a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response or nil
      def destroy(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        delete("/scans/#{scan_id}")
      end

      # Retrieves the latest status of a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] status data for the scan
      def status(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        get("/scans/#{scan_id}/latest-status")
      end

      # Pauses a running scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response
      def pause(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        post("/scans/#{scan_id}/pause")
      end

      # Resumes a paused scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response
      def resume(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        post("/scans/#{scan_id}/resume")
      end

      # Stops a running scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash, nil] parsed response
      def stop(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        post("/scans/#{scan_id}/stop")
      end

      # Copies a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Hash] the copied scan data
      def copy(scan_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        post("/scans/#{scan_id}/copy")
      end

      # Updates the schedule for a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param params [Hash] schedule configuration
      # @return [Hash] the updated schedule data
      def schedule(scan_id, params)
        validate_path_segment!(scan_id, name: 'scan_id')
        put("/scans/#{scan_id}/schedule", params)
      end

      # Retrieves the scan history from the scan details endpoint.
      #
      # @param scan_id [Integer, String] the scan ID
      # @return [Array<Hash>] array of history records
      def history(scan_id)
        data = details(scan_id)
        data['history'] || []
      end

      # Retrieves details for a specific host within a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param host_id [Integer, String] the host ID
      # @return [Hash] host details including vulnerability info
      def host_details(scan_id, host_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        validate_path_segment!(host_id, name: 'host_id')
        get("/scans/#{scan_id}/hosts/#{host_id}")
      end

      # Retrieves plugin output for a specific host and plugin within a scan.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param host_id [Integer, String] the host ID
      # @param plugin_id [Integer, String] the plugin ID
      # @return [Hash] plugin output data
      def plugin_output(scan_id, host_id, plugin_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        validate_path_segment!(host_id, name: 'host_id')
        validate_path_segment!(plugin_id, name: 'plugin_id')
        get("/scans/#{scan_id}/hosts/#{host_id}/plugins/#{plugin_id}")
      end

      # Initiates a scan report export.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param format [String, Symbol] export format — one of "nessus", "html", "pdf", "csv", or "db"
      # @param history_id [Integer, nil] optional scan history ID query parameter; required for "db" exports
      # @param body [Hash] additional export parameters (e.g., +chapters+ for PDF)
      # @return [Hash] response containing the file ID under +"file"+ key
      # @raise [ArgumentError] if required parameters are missing or format is not supported
      #
      # @example
      #   client.scans.export_request(123, format: 'pdf', chapters: 'vuln_hosts_summary')
      def export_request(scan_id, format:, history_id: nil, **body)
        validate_path_segment!(scan_id, name: 'scan_id')
        format = normalize_export_format(format)
        validate_export_format!(format)
        validate_export_request!(format, history_id: history_id, body: body)

        post(export_request_path(scan_id, history_id), body.merge(format: format))
      end

      # Retrieves the status of a scan export.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param file_id [Integer, String] the export file ID
      # @return [Hash] status data with +"status"+ key ("ready" or "loading")
      def export_status(scan_id, file_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        validate_path_segment!(file_id, name: 'file_id')
        get("/scans/#{scan_id}/export/#{file_id}/status")
      end

      # Downloads a completed scan export as raw binary data.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param file_id [Integer, String] the export file ID
      # @return [String] raw binary content of the export file
      def export_download(scan_id, file_id)
        validate_path_segment!(scan_id, name: 'scan_id')
        validate_path_segment!(file_id, name: 'file_id')
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
      def wait_for_export(scan_id, file_id, timeout: DEFAULT_EXPORT_TIMEOUT,
                          poll_interval: DEFAULT_EXPORT_POLL_INTERVAL)
        validate_path_segment!(scan_id, name: 'scan_id')
        validate_path_segment!(file_id, name: 'file_id')
        poll_until(timeout: timeout, poll_interval: poll_interval, label: "Scan export #{file_id}") do
          status_data = export_status(scan_id, file_id)
          status_data if status_data['status'] == 'ready'
        end
      end

      # Convenience method: requests an export, waits for completion, and downloads the result.
      #
      # @param scan_id [Integer, String] the scan ID
      # @param format [String, Symbol] export format — one of "nessus", "html", "pdf", "csv", or "db"
      # @param save_path [String, nil] if provided, writes binary content to this file path.
      #   The caller is responsible for ensuring the path is safe and writable.
      #   This value is used as-is with +File.binwrite+ — no sanitization is performed.
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
        validate_path_segment!(scan_id, name: 'scan_id')
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

      private

      def normalize_export_format(format)
        format.to_s
      end

      def validate_export_format!(format)
        return if SUPPORTED_EXPORT_FORMATS.include?(format)

        raise ArgumentError, "Unsupported format '#{format}'. Must be one of: #{SUPPORTED_EXPORT_FORMATS.join(', ')}"
      end

      def validate_export_request!(format, history_id:, body:)
        validate_chapters_requirement!(format, body[:chapters])
        validate_db_requirements!(format, history_id: history_id, body: body)
      end

      def validate_chapters_requirement!(format, chapters)
        return unless %w[pdf html].include?(format)
        return unless blank_value?(chapters)

        raise ArgumentError, "chapters is required when format is '#{format}'"
      end

      def validate_db_requirements!(format, history_id:, body:)
        return unless format == 'db'

        raise ArgumentError, "history_id is required when format is 'db'" if history_id.nil?
        raise ArgumentError, "asset_id is required when format is 'db'" if blank_value?(body[:asset_id])
        raise ArgumentError, "password is required when format is 'db'" if blank_value?(body[:password])
      end

      def export_request_path(scan_id, history_id)
        path = "/scans/#{scan_id}/export"
        return path if history_id.nil?

        "#{path}?#{URI.encode_www_form(history_id: history_id)}"
      end

      def blank_value?(value)
        value.nil? || value.to_s.strip.empty?
      end
    end
  end
end
