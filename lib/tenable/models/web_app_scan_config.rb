# frozen_string_literal: true

module Tenable
  module Models
    class WebAppScanConfig
      attr_reader :config_id, :name, :target, :status, :tracking_id

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
