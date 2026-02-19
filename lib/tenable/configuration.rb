# frozen_string_literal: true

module Tenable
  class Configuration
    attr_reader :access_key, :secret_key, :base_url, :timeout, :open_timeout, :max_retries, :logger

    DEFAULTS = {
      base_url: 'https://cloud.tenable.com',
      timeout: 30,
      open_timeout: 10,
      max_retries: 3
    }.freeze

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
