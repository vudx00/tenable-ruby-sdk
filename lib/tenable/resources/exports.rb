# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io vulnerability export endpoints.
    #
    # Exports allow bulk retrieval of vulnerability data in chunks.
    #
    # @example Full export workflow
    #   exports = client.exports
    #   result = exports.export(num_assets: 50)
    #   exports.wait_for_completion(result["export_uuid"])
    #   exports.each(result["export_uuid"]) { |vuln| process(vuln) }
    class Exports < Base
      # @return [Integer] default seconds between status polls
      DEFAULT_POLL_INTERVAL = 2

      # @return [Integer] default timeout in seconds for waiting on export completion
      DEFAULT_TIMEOUT = 300

      # Initiates a new vulnerability export.
      #
      # @param body [Hash] export request parameters (e.g., +num_assets+, +filters+)
      # @return [Hash] response containing the export UUID
      # @raise [ApiError] on non-2xx responses
      #
      # @example
      #   client.exports.export(num_assets: 50)
      def export(body = {})
        post('/vulns/export', body)
      end

      # Retrieves the status of an export.
      #
      # @param export_uuid [String] the export UUID
      # @return [Hash] status data including +"status"+ and +"chunks_available"+
      def status(export_uuid)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        get("/vulns/export/#{export_uuid}/status")
      end

      # Downloads a single chunk of export data.
      #
      # @param export_uuid [String] the export UUID
      # @param chunk_id [Integer] the chunk identifier
      # @return [Array<Hash>] array of vulnerability records
      def download_chunk(export_uuid, chunk_id)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        validate_path_segment!(chunk_id, name: 'chunk_id')
        get("/vulns/export/#{export_uuid}/chunks/#{chunk_id}")
      end

      # Cancels an in-progress vulnerability export.
      #
      # @param export_uuid [String] the export UUID
      # @return [Hash] cancellation response
      def cancel(export_uuid)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        post("/vulns/export/#{export_uuid}/cancel")
      end

      # Iterates over all available chunks for a completed export.
      #
      # @param export_uuid [String] the export UUID
      # @yield [record] yields each vulnerability record
      # @yieldparam record [Hash] a single vulnerability record
      # @return [void]
      #
      # @example
      #   client.exports.each(uuid) do |vuln|
      #     puts vuln["plugin_name"]
      #   end
      def each(export_uuid, &block)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        return enum_for(:each, export_uuid) unless block

        status_data = status(export_uuid)
        chunks = status_data['chunks_available'] || []
        chunks.each do |chunk_id|
          records = download_chunk(export_uuid, chunk_id)
          records.each(&block)
        end
      end

      # Polls until the export reaches FINISHED or ERROR status.
      #
      # @param export_uuid [String] the export UUID
      # @param timeout [Integer] maximum seconds to wait (default: 300)
      # @param poll_interval [Integer] seconds between status checks (default: 2)
      # @return [Hash] the final status data when export is FINISHED
      # @raise [Tenable::TimeoutError] if the export does not finish within the timeout
      # @raise [Tenable::ApiError] if the export status is ERROR
      def wait_for_completion(export_uuid, timeout: DEFAULT_TIMEOUT, poll_interval: DEFAULT_POLL_INTERVAL)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        poll_until(timeout: timeout, poll_interval: poll_interval, label: "Export #{export_uuid}") do
          status_data = status(export_uuid)
          raise Tenable::ApiError, "Export #{export_uuid} failed" if status_data['status'] == 'ERROR'

          status_data if status_data['status'] == 'FINISHED'
        end
      end
    end
  end
end
