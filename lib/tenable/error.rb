# frozen_string_literal: true

module Tenable
  class Error < StandardError; end

  class AuthenticationError < Error
    DEFAULT_MESSAGE = 'Authentication failed. Verify your access key and secret key are correct.'

    def initialize(msg = DEFAULT_MESSAGE)
      super
    end
  end

  class ApiError < Error
    attr_reader :status_code, :body

    def initialize(msg = nil, status_code: nil, body: nil)
      @status_code = status_code
      @body = body
      message = msg || "API request failed with status #{status_code}"
      message = "#{message}: #{body}" if body
      super(message)
    end
  end

  class RateLimitError < ApiError
    def initialize(msg = 'Rate limit exceeded. Retries exhausted.', **kwargs)
      super
    end
  end

  class ConnectionError < Error
    def initialize(msg = 'Connection to Tenable API failed. Check your network and base_url configuration.')
      super
    end
  end

  class TimeoutError < Error
    def initialize(msg = 'Request timed out. Consider increasing the timeout configuration.')
      super
    end
  end

  class ParseError < Error
    def initialize(msg = 'Failed to parse API response. The response may be malformed.')
      super
    end
  end
end
