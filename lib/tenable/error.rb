# frozen_string_literal: true

module Tenable
  # Base error class for all Tenable SDK errors.
  class Error < StandardError; end

  # Raised when API authentication fails (HTTP 401).
  class AuthenticationError < Error
    DEFAULT_MESSAGE = 'Authentication failed. Verify your access key and secret key are correct.'

    def initialize(msg = DEFAULT_MESSAGE)
      super
    end
  end

  # Raised for non-success HTTP responses from the Tenable API.
  class ApiError < Error
    # @return [Integer, nil] the HTTP status code
    attr_reader :status_code

    # @return [String, nil] the response body
    attr_reader :body

    # @param msg [String, nil] custom error message
    # @param status_code [Integer, nil] HTTP status code
    # @param body [String, nil] response body
    def initialize(msg = nil, status_code: nil, body: nil)
      @status_code = status_code
      @body = body
      message = msg || "API request failed with status #{status_code}"
      message = "#{message}: #{body}" if body
      super(message)
    end
  end

  # Raised when the API rate limit is exceeded and retries are exhausted (HTTP 429).
  class RateLimitError < ApiError
    def initialize(msg = 'Rate limit exceeded. Retries exhausted.', **kwargs)
      super
    end
  end

  # Raised when a network connection to the Tenable API cannot be established.
  class ConnectionError < Error
    def initialize(msg = 'Connection to Tenable API failed. Check your network and base_url configuration.')
      super
    end
  end

  # Raised when an API request exceeds the configured timeout.
  class TimeoutError < Error
    def initialize(msg = 'Request timed out. Consider increasing the timeout configuration.')
      super
    end
  end

  # Raised when the API response body cannot be parsed as JSON.
  class ParseError < Error
    def initialize(msg = 'Failed to parse API response. The response may be malformed.')
      super
    end
  end
end
