# frozen_string_literal: true

module Tenable
  module Resources
    class Base
      def initialize(connection)
        @connection = connection
      end

      private

      def get(path, params = {})
        response = @connection.faraday.get(path, params)
        handle_response(response)
      end

      def post(path, body = nil)
        response = @connection.faraday.post(path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = JSON.generate(body) if body
        end
        handle_response(response)
      end

      def handle_response(response)
        case response.status
        when 200..299
          parse_body(response)
        when 401
          raise AuthenticationError
        when 429
          raise RateLimitError.new(status_code: response.status, body: response.body)
        else
          raise ApiError.new(status_code: response.status, body: response.body)
        end
      end

      def parse_body(response)
        return nil if response.body.nil? || response.body.empty?

        JSON.parse(response.body)
      rescue JSON::ParserError
        raise ParseError, "Failed to parse response: #{response.body[0..100]}"
      end
    end
  end
end
