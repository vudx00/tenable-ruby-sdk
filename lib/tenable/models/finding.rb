# frozen_string_literal: true

module Tenable
  module Models
    # Represents a web application scan finding.
    Finding = Data.define(:finding_id, :severity, :url, :name, :description, :remediation, :plugin_id) do
      # Builds a Finding from a raw API response hash.
      #
      # @param data [Hash] raw API response hash with string keys
      # @return [Finding]
      def self.from_api(data)
        data = data.transform_keys(&:to_sym)
        new(
          finding_id: data[:finding_id],
          severity: data[:severity],
          url: data[:url],
          name: data[:name],
          description: data[:description],
          remediation: data[:remediation],
          plugin_id: data[:plugin_id]
        )
      end
    end
  end
end
