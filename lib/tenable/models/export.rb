# frozen_string_literal: true

module Tenable
  module Models
    # Represents the status of a vulnerability export job.
    Export = Data.define(:uuid, :status, :chunks_available, :chunks_failed, :chunks_cancelled) do
      # Builds an Export from a raw API response hash.
      #
      # @param data [Hash] raw API response hash with string keys
      # @return [Export]
      def self.from_api(data)
        data = data.transform_keys(&:to_sym)
        new(
          uuid: data[:uuid],
          status: data[:status],
          chunks_available: data[:chunks_available] || [],
          chunks_failed: data[:chunks_failed] || [],
          chunks_cancelled: data[:chunks_cancelled] || []
        )
      end

      # @return [Boolean] true if the export has completed successfully
      def finished?
        status == 'FINISHED'
      end

      # @return [Boolean] true if the export is still processing
      def processing?
        status == 'PROCESSING'
      end

      # @return [Boolean] true if the export encountered an error
      def error?
        status == 'ERROR'
      end

      # @return [Boolean] true if the export is queued
      def queued?
        status == 'QUEUED'
      end
    end
  end
end
