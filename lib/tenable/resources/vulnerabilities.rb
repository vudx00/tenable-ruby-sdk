# frozen_string_literal: true

module Tenable
  module Resources
    # Provides access to the Tenable.io vulnerability workbench endpoints.
    class Vulnerabilities < Base
      # Lists vulnerabilities from the workbench.
      #
      # @param params [Hash] optional query parameters for filtering
      # @return [Hash] parsed API response containing vulnerability data
      # @raise [AuthenticationError] on 401 responses
      # @raise [ApiError] on other non-2xx responses
      #
      # @example
      #   client.vulnerabilities.list(date_range: 7)
      def list(params = {})
        get('/workbenches/vulnerabilities', params)
      end
    end
  end
end
