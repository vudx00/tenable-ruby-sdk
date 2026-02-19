# frozen_string_literal: true

module Tenable
  # Manages the Faraday HTTP connection with configured middleware.
  #
  # Automatically configures authentication, retry, and logging middleware
  # based on the provided {Configuration}.
  class Connection
    # @return [Faraday::Connection] the underlying Faraday connection
    attr_reader :faraday

    # Creates a new connection from the given configuration.
    #
    # @param config [Configuration] a validated configuration instance
    # @raise [ArgumentError] if the base_url does not use HTTPS
    def initialize(config)
      @config = config
      validate_tls!
      @faraday = build_connection
    end

    private

    def validate_tls!
      uri = URI.parse(@config.base_url)
      raise ArgumentError, "base_url must use HTTPS: #{@config.base_url}" unless uri.scheme == 'https'
    end

    def build_connection
      Faraday.new(url: @config.base_url) do |f|
        f.use Middleware::Authentication,
              access_key: @config.access_key,
              secret_key: @config.secret_key
        f.use Middleware::Retry, max_retries: @config.max_retries
        f.use Middleware::Logging, logger: @config.logger
        f.options.timeout = @config.timeout
        f.options.open_timeout = @config.open_timeout
        f.adapter Faraday.default_adapter
      end
    end
  end
end
