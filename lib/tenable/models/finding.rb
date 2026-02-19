# frozen_string_literal: true

module Tenable
  module Models
    # Represents a web application scan finding.
    class Finding
      # @return [String, nil] unique finding identifier
      attr_reader :finding_id

      # @return [String, nil] severity level
      attr_reader :severity

      # @return [String, nil] the URL where the finding was detected
      attr_reader :url

      # @return [String, nil] finding name
      attr_reader :name

      # @return [String, nil] detailed description
      attr_reader :description

      # @return [String, nil] remediation guidance
      attr_reader :remediation

      # @return [Integer, nil] associated plugin ID
      attr_reader :plugin_id

      # @param data [Hash] raw API response hash
      def initialize(data)
        @finding_id = data['finding_id']
        @severity = data['severity']
        @url = data['url']
        @name = data['name']
        @description = data['description']
        @remediation = data['remediation']
        @plugin_id = data['plugin_id']
      end
    end
  end
end
