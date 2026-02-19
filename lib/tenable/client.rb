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
    def initialize(**options)
      @configuration = Configuration.new(**options)
      @connection = Connection.new(@configuration)
      freeze
    end

    # Returns a vulnerabilities resource for querying vulnerability data.
    #
    # @return [Resources::Vulnerabilities]
    def vulnerabilities
      Resources::Vulnerabilities.new(@connection)
    end

    # Returns an exports resource for bulk data export operations.
    #
    # @return [Resources::Exports]
    def exports
      Resources::Exports.new(@connection)
    end

    # Returns an asset exports resource for bulk asset export operations.
    #
    # @return [Resources::AssetExports]
    def asset_exports
      Resources::AssetExports.new(@connection)
    end

    # Returns a scans resource for managing vulnerability scans.
    #
    # @return [Resources::Scans]
    def scans
      Resources::Scans.new(@connection)
    end

    # Returns a web application scans resource.
    #
    # @return [Resources::WebAppScans]
    def web_app_scans
      Resources::WebAppScans.new(@connection)
    end
  end
end
