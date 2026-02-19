# frozen_string_literal: true

module Tenable
  module Resources
    class WebAppScans < Base
      TERMINAL_STATUSES = %w[completed failed cancelled error].freeze
      DEFAULT_POLL_INTERVAL = 2

      def create_config(name:, target:)
        post('/was/v2/configs', { 'name' => name, 'target' => target })
      end

      def launch(config_id)
        post("/was/v2/configs/#{config_id}/scans")
      end

      def status(config_id, scan_id)
        get("/was/v2/configs/#{config_id}/scans/#{scan_id}")
      end

      def findings(config_id, **params)
        get("/was/v2/configs/#{config_id}/findings", params)
      end

      def wait_until_complete(config_id, scan_id, poll_interval: DEFAULT_POLL_INTERVAL)
        loop do
          result = status(config_id, scan_id)
          return result if TERMINAL_STATUSES.include?(result['status'])

          sleep(poll_interval)
        end
      end
    end
  end
end
