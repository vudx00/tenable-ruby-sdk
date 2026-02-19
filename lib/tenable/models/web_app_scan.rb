# frozen_string_literal: true

module Tenable
  module Models
    # Represents a web application scan instance.
    class WebAppScan
      # @return [String, nil] the scan ID
      attr_reader :scan_id

      # @return [String, nil] the configuration ID
      attr_reader :config_id

      # @return [String, nil] current scan status
      attr_reader :status

      # @return [String, nil] ISO 8601 timestamp when the scan started
      attr_reader :started_at

      # @return [String, nil] ISO 8601 timestamp when the scan completed
      attr_reader :completed_at

      # @return [Integer] number of findings discovered
      attr_reader :findings_count

      # @param data [Hash] raw API response hash
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
