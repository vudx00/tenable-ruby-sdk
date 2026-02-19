# frozen_string_literal: true

module Tenable
  module Resources
    class Scans < Base
      def list
        get('/scans')
      end

      def create(params)
        post('/scans', params)
      end

      def launch(scan_id)
        post("/scans/#{scan_id}/launch")
      end

      def status(scan_id)
        get("/scans/#{scan_id}/latest-status")
      end
    end
  end
end
