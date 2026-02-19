# frozen_string_literal: true

module Tenable
  module Models
    class Export
      attr_reader :uuid, :status, :chunks_available, :chunks_failed, :chunks_cancelled

      def initialize(data)
        @uuid = data['uuid']
        @status = data['status']
        @chunks_available = data['chunks_available'] || []
        @chunks_failed = data['chunks_failed'] || []
        @chunks_cancelled = data['chunks_cancelled'] || []
      end

      def finished?
        @status == 'FINISHED'
      end

      def processing?
        @status == 'PROCESSING'
      end

      def error?
        @status == 'ERROR'
      end

      def queued?
        @status == 'QUEUED'
      end
    end
  end
end
