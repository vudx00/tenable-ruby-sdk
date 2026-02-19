# frozen_string_literal: true

module Tenable
  module Models
    # Represents a web application scan configuration.
    class WebAppScanConfig
      # @return [String, nil] the configuration ID
      attr_reader :config_id

      # @return [String, nil] the configuration name
      attr_reader :name

      # @return [String, nil] the target URL
      attr_reader :target

      # @return [String, nil] current configuration status
      attr_reader :status

      # @return [String, nil] tracking identifier
      attr_reader :tracking_id

      # @param data [Hash] raw API response hash
      def initialize(data)
        @config_id = data['config_id']
        @name = data['name']
        @target = data['target']
        @status = data['status']
        @tracking_id = data['tracking_id']
      end
    end
  end
end
