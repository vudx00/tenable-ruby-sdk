# frozen_string_literal: true

module Tenable
  module Resources
    # Base class for all API resource classes. Provides HTTP helpers
    # and response handling with automatic error mapping.
    class Base
      # @param connection [Connection] an initialized API connection
      def initialize(connection)
        @connection = connection
      end

      private

      # Performs a GET request.
      #
      # @param path [String] the API endpoint path
      # @param params [Hash] query parameters
      # @return [Hash, Array, nil] parsed JSON response
      # @raise [AuthenticationError] on 401 responses
      # @raise [RateLimitError] on 429 responses
      # @raise [ApiError] on other non-2xx responses
      # @raise [ParseError] if the response is not valid JSON
      def get(path, params = {})
        response = @connection.faraday.get(path, params)
        handle_response(response)
      end

      # Performs a POST request with a JSON body.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash, nil] request body (serialized to JSON)
      # @return [Hash, Array, nil] parsed JSON response
      # @raise [AuthenticationError] on 401 responses
      # @raise [RateLimitError] on 429 responses
      # @raise [ApiError] on other non-2xx responses
      # @raise [ParseError] if the response is not valid JSON
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

      # Performs a GET request and returns the raw response body without JSON parsing.
      # Useful for binary downloads (e.g., PDF, Nessus files).
      #
      # @param path [String] the API endpoint path
      # @param params [Hash] query parameters
      # @return [String] raw response body
      # @raise [AuthenticationError] on 401 responses
      # @raise [RateLimitError] on 429 responses
      # @raise [ApiError] on other non-2xx responses
      def get_raw(path, params = {})
        response = @connection.faraday.get(path, params)
        handle_response_raw(response)
      end

      def handle_response_raw(response)
        case response.status
        when 200..299
          response.body
        when 401
          raise AuthenticationError
        when 429
          raise RateLimitError.new(status_code: response.status, body: response.body)
        else
          raise ApiError.new(status_code: response.status, body: response.body)
        end
      end
    end
  end
end
