# frozen_string_literal: true

module Tenable
  module Middleware
    class Retry < Faraday::Middleware
      DEFAULT_MAX_RETRIES = 3
      RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze
      BASE_DELAY = 1

      def initialize(app, max_retries: DEFAULT_MAX_RETRIES)
        super(app)
        @max_retries = max_retries
      end

      def call(env)
        attempt = 0
        loop do
          attempt += 1
          response = @app.call(env.dup)

          return response unless retryable?(response.status)

          raise_if_exhausted(response, attempt) if attempt >= @max_retries

          sleep(retry_delay(response, attempt))
        end
      rescue Faraday::Error
        raise if attempt >= @max_retries

        sleep(BASE_DELAY * (2**(attempt - 1)))
        retry
      end

      private

      def retryable?(status)
        RETRYABLE_STATUS_CODES.include?(status)
      end

      def retry_delay(response, attempt)
        retry_after = response.headers&.[]('Retry-After')
        return retry_after.to_i if retry_after

        BASE_DELAY * (2**(attempt - 1))
      end

      def raise_if_exhausted(response, attempts)
        if response.status == 429
          raise Tenable::RateLimitError.new(
            "Rate limit exceeded after #{attempts} attempts",
            status_code: response.status,
            body: response.body
          )
        end

        raise Tenable::ApiError.new(
          "Request failed after #{attempts} attempts",
          status_code: response.status,
          body: response.body
        )
      end
    end
  end
end
