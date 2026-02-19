# frozen_string_literal: true

module Tenable
  module Resources
    class Vulnerabilities < Base
      def list(params = {})
        get('/workbenches/vulnerabilities', params)
      end
    end
  end
end
