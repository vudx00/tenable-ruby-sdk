# frozen_string_literal: true

module Tenable
  # Holds and validates all configuration options for the Tenable client.
  #
  # Configuration values can be passed directly or read from environment
  # variables (+TENABLE_ACCESS_KEY+, +TENABLE_SECRET_KEY+).
  class Configuration
    # @return [String] the API access key
    attr_reader :access_key

    # @return [String] the API secret key
    attr_reader :secret_key

    # @return [String] the API base URL
    attr_reader :base_url

    # @return [Integer] the request timeout in seconds
    attr_reader :timeout

    # @return [Integer] the connection open timeout in seconds
    attr_reader :open_timeout

    # @return [Integer] the maximum number of retry attempts
    attr_reader :max_retries

    # @return [Logger, nil] optional logger instance
    attr_reader :logger

    DEFAULTS = {
      base_url: 'https://cloud.tenable.com',
      timeout: 30,
      open_timeout: 10,
      max_retries: 3
    }.freeze

    # Creates a new Configuration instance.
    #
    # @param access_key [String, nil] API access key (falls back to +TENABLE_ACCESS_KEY+ env var)
    # @param secret_key [String, nil] API secret key (falls back to +TENABLE_SECRET_KEY+ env var)
    # @param base_url [String, nil] API base URL (default: https://cloud.tenable.com)
    # @param timeout [Integer, nil] request timeout in seconds (default: 30)
    # @param open_timeout [Integer, nil] connection open timeout in seconds (default: 10)
    # @param max_retries [Integer, nil] max retry attempts, 0-10 (default: 3)
    # @param logger [Logger, nil] optional logger for request/response logging
    # @raise [ArgumentError] if credentials are missing, base_url is invalid, or numeric values are out of range
    def initialize(access_key: nil, secret_key: nil, base_url: nil, timeout: nil, open_timeout: nil, max_retries: nil,
                   logger: nil)
      @access_key = access_key || ENV.fetch('TENABLE_ACCESS_KEY', nil)
      @secret_key = secret_key || ENV.fetch('TENABLE_SECRET_KEY', nil)
      @base_url = base_url || DEFAULTS[:base_url]
      @timeout = timeout || DEFAULTS[:timeout]
      @open_timeout = open_timeout || DEFAULTS[:open_timeout]
      @max_retries = max_retries.nil? ? DEFAULTS[:max_retries] : max_retries
      @logger = logger

      validate!
      freeze
    end

    private

    def validate!
      validate_credentials!
      validate_base_url!
      validate_timeouts!
      validate_max_retries!
    end

    def validate_credentials!
      raise ArgumentError, 'access_key is required (pass directly or set TENABLE_ACCESS_KEY)' if blank?(@access_key)
      raise ArgumentError, 'secret_key is required (pass directly or set TENABLE_SECRET_KEY)' if blank?(@secret_key)
    end

    def validate_base_url!
      uri = URI.parse(@base_url)
      raise ArgumentError, "base_url must use HTTPS: #{@base_url}" unless uri.scheme == 'https'
    rescue URI::InvalidURIError
      raise ArgumentError, "base_url is not a valid URL: #{@base_url}"
    end

    def validate_timeouts!
      unless @timeout.is_a?(Integer) && @timeout.positive?
        raise ArgumentError,
              "timeout must be positive, got #{@timeout}"
      end

      return if @open_timeout.is_a?(Integer) && @open_timeout.positive?

      raise ArgumentError, "open_timeout must be positive, got #{@open_timeout}"
    end

    def validate_max_retries!
      return if @max_retries.is_a?(Integer) && @max_retries >= 0 && @max_retries <= 10

      raise ArgumentError, "max_retries must be between 0 and 10, got #{@max_retries}"
    end

    def blank?(value)
      value.nil? || (value.is_a?(String) && value.strip.empty?)
    end
  end
end
