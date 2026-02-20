# frozen_string_literal: true

module Tenable
  # Primary entry point for the Tenable.io API.
  #
  # @example Basic usage
  #   client = Tenable::Client.new(access_key: "ak", secret_key: "sk")
  #   client.vulnerabilities.list
  class Client
    # @return [Configuration] the client configuration
    attr_reader :configuration

    # @return [Resources::Vulnerabilities]
    attr_reader :vulnerabilities

    # @return [Resources::Exports]
    attr_reader :exports

    # @return [Resources::AssetExports]
    attr_reader :asset_exports

    # @return [Resources::Scans]
    attr_reader :scans

    # @return [Resources::WebAppScans]
    attr_reader :web_app_scans

    # Creates a new Tenable API client.
    #
    # @param options [Hash] configuration options passed to {Configuration#initialize}
    # @option options [String] :access_key Tenable.io API access key
    # @option options [String] :secret_key Tenable.io API secret key
    # @option options [String] :base_url API base URL (default: https://cloud.tenable.com)
    # @option options [Integer] :timeout request timeout in seconds (default: 30)
    # @option options [Integer] :open_timeout connection open timeout in seconds (default: 10)
    # @option options [Integer] :max_retries maximum retry attempts (default: 3)
    # @option options [Logger] :logger optional logger instance
    # @raise [ArgumentError] if required credentials are missing or options are invalid
    #
    # @example
    #   client = Tenable::Client.new(
    #     access_key: "your-access-key",
    #     secret_key: "your-secret-key",
    #     timeout: 60
    #   )
    def initialize(**)
      @configuration = Configuration.new(**)
      connection = Connection.new(@configuration)
      @vulnerabilities = Resources::Vulnerabilities.new(connection)
      @exports = Resources::Exports.new(connection)
      @asset_exports = Resources::AssetExports.new(connection)
      @scans = Resources::Scans.new(connection)
      @web_app_scans = Resources::WebAppScans.new(connection)
      freeze
    end
  end
end
