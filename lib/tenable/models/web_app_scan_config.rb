# frozen_string_literal: true

module Tenable
  module Models
    # Represents a web application scan configuration.
    WebAppScanConfig = Data.define(:config_id, :name, :target, :status, :tracking_id) do
      # Builds a WebAppScanConfig from a raw API response hash.
      #
      # @param data [Hash] raw API response hash with string keys
      # @return [WebAppScanConfig]
      def self.from_api(data)
        data = data.transform_keys(&:to_sym)
        new(
          config_id: data[:config_id],
          name: data[:name],
          target: data[:target],
          status: data[:status],
          tracking_id: data[:tracking_id]
        )
      end
    end
  end
end
