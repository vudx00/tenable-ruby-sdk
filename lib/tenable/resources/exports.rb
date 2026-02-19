# frozen_string_literal: true

module Tenable
  module Resources
    class Exports < Base
      DEFAULT_POLL_INTERVAL = 2
      DEFAULT_TIMEOUT = 300

      def export(body = {})
        post('/vulns/export', body)
      end

      def status(export_uuid)
        get("/vulns/export/#{export_uuid}/status")
      end

      def download_chunk(export_uuid, chunk_id)
        get("/vulns/export/#{export_uuid}/chunks/#{chunk_id}")
      end

      def each(export_uuid, &block)
        status_data = status(export_uuid)
        chunks = status_data['chunks_available'] || []
        chunks.each do |chunk_id|
          records = download_chunk(export_uuid, chunk_id)
          records.each(&block)
        end
      end

      def wait_for_completion(export_uuid, timeout: DEFAULT_TIMEOUT, poll_interval: DEFAULT_POLL_INTERVAL)
        deadline = Time.now + timeout
        loop do
          raise Tenable::TimeoutError, "Export #{export_uuid} timed out" if Time.now >= deadline

          status_data = status(export_uuid)
          return status_data if status_data['status'] == 'FINISHED'
          raise Tenable::ApiError, "Export #{export_uuid} failed" if status_data['status'] == 'ERROR'

          sleep(poll_interval)
        end
      end
    end
  end
end
