# frozen_string_literal: true

module Tenable
  module Models
    class WebAppScan
      attr_reader :scan_id, :config_id, :status, :started_at, :completed_at, :findings_count

      def initialize(data)
        @scan_id = data['scan_id']
        @config_id = data['config_id']
        @status = data['status']
        @started_at = data['started_at']
        @completed_at = data['completed_at']
        @findings_count = data['findings_count'] || 0
      end
    end
  end
end
