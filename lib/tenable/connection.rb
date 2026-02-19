# frozen_string_literal: true

module Tenable
  class Connection
    attr_reader :faraday

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
