# frozen_string_literal: true

module Tenable
  module Models
    class Finding
      attr_reader :finding_id, :severity, :url, :name, :description, :remediation, :plugin_id

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
