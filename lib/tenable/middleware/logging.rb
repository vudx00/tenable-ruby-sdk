# frozen_string_literal: true

module Tenable
  module Middleware
    class Logging < Faraday::Middleware
      API_KEY_PATTERN = /accessKey=[^;]*;?\s*secretKey=[^;]*/

      def initialize(app, logger: nil)
        super(app)
        @logger = logger
      end

      def call(env)
        log_request(env) if @logger
        @app.call(env).on_complete do |response_env|
          log_response(response_env) if @logger
        end
      rescue StandardError => e
        @logger&.error("Tenable request error: #{e.message}")
        raise
      end

      private

      def log_request(env)
        headers = redact_headers(env.request_headers)
        @logger.debug("Tenable request: #{env.method.upcase} #{env.url} headers=#{headers}")
      end

      def log_response(env)
        @logger.debug("Tenable response: status=#{env.status}")
      end

      def redact_headers(headers)
        headers.transform_values do |value|
          value.is_a?(String) ? value.gsub(API_KEY_PATTERN, '[REDACTED]') : value
        end
      end
    end
  end
end
