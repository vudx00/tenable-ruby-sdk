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

      # Retrieves detailed information for a specific vulnerability plugin.
      #
      # @param plugin_id [Integer, String] the plugin ID
      # @param params [Hash] optional query parameters
      # @return [Hash] vulnerability info data
      def info(plugin_id, params = {})
        get("/workbenches/vulnerabilities/#{plugin_id}/info", params)
      end

      # Retrieves plugin outputs for a specific vulnerability.
      #
      # @param plugin_id [Integer, String] the plugin ID
      # @param params [Hash] optional query parameters
      # @return [Hash] plugin output data
      def outputs(plugin_id, params = {})
        get("/workbenches/vulnerabilities/#{plugin_id}/outputs", params)
      end

      # Lists assets from the workbench.
      #
      # @param params [Hash] optional query parameters for filtering
      # @return [Hash] parsed API response containing asset data
      def assets(params = {})
        get('/workbenches/assets', params)
      end

      # Retrieves detailed information for a specific asset.
      #
      # @param asset_id [String] the asset UUID
      # @param params [Hash] optional query parameters
      # @return [Hash] asset info data
      def asset_info(asset_id, params = {})
        get("/workbenches/assets/#{asset_id}/info", params)
      end

      # Lists vulnerabilities for a specific asset.
      #
      # @param asset_id [String] the asset UUID
      # @param params [Hash] optional query parameters
      # @return [Hash] vulnerability data for the asset
      def asset_vulnerabilities(asset_id, params = {})
        get("/workbenches/assets/#{asset_id}/vulnerabilities", params)
      end
    end
  end
end
