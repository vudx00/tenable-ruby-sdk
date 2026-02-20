# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io asset export endpoints.
    #
    # Exports allow bulk retrieval of asset data in chunks.
    #
    # @example Full export workflow
    #   asset_exports = client.asset_exports
    #   result = asset_exports.export(chunk_size: 100)
    #   asset_exports.wait_for_completion(result["export_uuid"])
    #   asset_exports.each(result["export_uuid"]) { |asset| process(asset) }
    class AssetExports < Base
      # @return [Integer] default seconds between status polls
      DEFAULT_POLL_INTERVAL = 2

      # @return [Integer] default timeout in seconds for waiting on export completion
      DEFAULT_TIMEOUT = 300

      # Initiates a new asset export.
      #
      # @param body [Hash] export request parameters (e.g., +chunk_size+, +filters+)
      # @return [Hash] response containing the export UUID
      def export(body = {})
        post('/assets/v2/export', body)
      end

      # Retrieves the status of an asset export.
      #
      # @param export_uuid [String] the export UUID
      # @return [Hash] status data including +"status"+ and +"chunks_available"+
      def status(export_uuid)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        get("/assets/export/#{export_uuid}/status")
      end

      # Downloads a single chunk of asset export data.
      #
      # @param export_uuid [String] the export UUID
      # @param chunk_id [Integer] the chunk identifier
      # @return [Array<Hash>] array of asset records
      def download_chunk(export_uuid, chunk_id)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        validate_path_segment!(chunk_id, name: 'chunk_id')
        get("/assets/export/#{export_uuid}/chunks/#{chunk_id}")
      end

      # Cancels an in-progress asset export.
      #
      # @param export_uuid [String] the export UUID
      # @return [Hash] cancellation response
      def cancel(export_uuid)
        validate_path_segment!(export_uuid, name: 'export_uuid')
        post("/assets/export/#{export_uuid}/cancel")
      end

      # Iterates over all available chunks for a completed export.
      #
      # @param export_uuid [String] the export UUID
      # @yield [record] yields each asset record
      # @yieldparam record [Hash] a single asset record
      # @return [void]
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
        poll_until(timeout: timeout, poll_interval: poll_interval, label: "Asset export #{export_uuid}") do
          status_data = status(export_uuid)
          raise Tenable::ApiError, "Asset export #{export_uuid} failed" if status_data['status'] == 'ERROR'

          status_data if status_data['status'] == 'FINISHED'
        end
      end
    end
  end
end
