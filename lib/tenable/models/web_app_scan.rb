# frozen_string_literal: true

module Tenable
  module Models
    # Represents a web application scan instance.
    WebAppScan = Data.define(:scan_id, :config_id, :status, :started_at, :completed_at, :findings_count) do
      # Builds a WebAppScan from a raw API response hash.
      #
      # @param data [Hash] raw API response hash with string keys
      # @return [WebAppScan]
      def self.from_api(data)
        data = data.transform_keys(&:to_sym)
        new(
          scan_id: data[:scan_id],
          config_id: data[:config_id],
          status: data[:status],
          started_at: data[:started_at],
          completed_at: data[:completed_at],
          findings_count: data[:findings_count] || 0
        )
      end
    end
  end
end
