# frozen_string_literal: true

module Tenable
  module Middleware
    class Authentication < Faraday::Middleware
      def initialize(app, access_key:, secret_key:)
        super(app)
        @access_key = access_key
        @secret_key = secret_key
      end

      def on_request(env)
        env.request_headers['X-ApiKeys'] = "accessKey=#{@access_key};secretKey=#{@secret_key};"
      end

      def inspect
        "#<#{self.class.name} [REDACTED]>"
      end

      def to_s
        inspect
      end
    end
  end
end
