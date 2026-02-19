# frozen_string_literal: true

module Tenable
  module Models
    # Represents the status of a vulnerability export job.
    class Export
      # @return [String, nil] the export UUID
      attr_reader :uuid

      # @return [String, nil] current status (QUEUED, PROCESSING, FINISHED, ERROR)
      attr_reader :status

      # @return [Array<Integer>] chunk IDs available for download
      attr_reader :chunks_available

      # @return [Array<Integer>] chunk IDs that failed processing
      attr_reader :chunks_failed

      # @return [Array<Integer>] chunk IDs that were cancelled
      attr_reader :chunks_cancelled

      # @param data [Hash] raw API response hash
      def initialize(data)
        @uuid = data['uuid']
        @status = data['status']
        @chunks_available = data['chunks_available'] || []
        @chunks_failed = data['chunks_failed'] || []
        @chunks_cancelled = data['chunks_cancelled'] || []
      end

      # @return [Boolean] true if the export has completed successfully
      def finished?
        @status == 'FINISHED'
      end

      # @return [Boolean] true if the export is still processing
      def processing?
        @status == 'PROCESSING'
      end

      # @return [Boolean] true if the export encountered an error
      def error?
        @status == 'ERROR'
      end

      # @return [Boolean] true if the export is queued
      def queued?
        @status == 'QUEUED'
      end
    end
  end
end
