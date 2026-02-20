# frozen_string_literal: true

module Tenable
  module Resources
    # Base class for all API resource classes. Provides HTTP helpers
    # and response handling with automatic error mapping.
    class Base
      include Pollable

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

      # Performs a PUT request with a JSON body.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash, nil] request body (serialized to JSON)
      # @return [Hash, Array, nil] parsed JSON response
      def put(path, body = nil)
        response = @connection.faraday.put(path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = JSON.generate(body) if body
        end
        handle_response(response)
      end

      # Performs a PATCH request with a JSON body.
      #
      # @param path [String] the API endpoint path
      # @param body [Hash, nil] request body (serialized to JSON)
      # @return [Hash, Array, nil] parsed JSON response
      def patch(path, body = nil)
        response = @connection.faraday.patch(path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = JSON.generate(body) if body
        end
        handle_response(response)
      end

      # Performs a DELETE request.
      #
      # @param path [String] the API endpoint path
      # @param params [Hash] query parameters
      # @return [Hash, Array, nil] parsed JSON response
      def delete(path, params = {})
        response = @connection.faraday.delete(path, params)
        handle_response(response)
      end

      def handle_response(response)
        raise_for_status(response)
        parse_body(response)
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
        raise_for_status(response)
        response.body
      end

      # Validates that a value is safe to interpolate into a URL path segment.
      # Rejects path traversal attempts (/, ..) and non-printable characters.
      #
      # @param value [String, Integer] the path segment to validate
      # @param name [String] parameter name for error messages
      # @raise [ArgumentError] if the value contains unsafe characters
      def validate_path_segment!(value, name: 'id')
        str = value.to_s
        return unless str.empty? || str.include?('/') || str.include?('..') || str.match?(/[^[:print:]]/)

        raise ArgumentError, "Invalid #{name}: contains unsafe characters"
      end

      def raise_for_status(response)
        case response.status
        when 200..299 then nil
        when 401      then raise AuthenticationError
        when 429      then raise RateLimitError.new(status_code: response.status, body: response.body)
        else               raise ApiError.new(status_code: response.status, body: response.body)
        end
      end
    end
  end
end
