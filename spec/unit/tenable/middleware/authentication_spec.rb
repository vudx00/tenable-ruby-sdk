# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Middleware::Authentication do
  let(:access_key) { 'test-access-key-1234' }
  let(:secret_key) { 'test-secret-key-5678' }

  let(:connection) do
    Faraday.new do |f|
      f.use described_class, access_key: access_key, secret_key: secret_key
      f.adapter :test do |stub|
        stub.get('/test') { |env| [200, env.request_headers, 'ok'] }
      end
    end
  end

  describe 'header injection' do
    it 'injects X-ApiKeys header with the correct format' do
      response = connection.get('/test')
      expect(response.headers['X-ApiKeys']).to eq(
        "accessKey=#{access_key};secretKey=#{secret_key};"
      )
    end
  end

  describe 'key redaction' do
    subject(:middleware) do
      described_class.new(->(_env) {}, access_key: access_key, secret_key: secret_key)
    end

    it 'does not expose access_key in inspect output' do
      expect(middleware.inspect).not_to include(access_key)
    end

    it 'does not expose secret_key in inspect output' do
      expect(middleware.inspect).not_to include(secret_key)
    end

    it 'does not expose access_key in to_s output' do
      expect(middleware.to_s).not_to include(access_key)
    end

    it 'does not expose secret_key in to_s output' do
      expect(middleware.to_s).not_to include(secret_key)
    end
  end

  describe 'request passthrough' do
    it 'passes the request to the next middleware and returns the response' do
      response = connection.get('/test')
      expect(response.status).to eq(200)
      expect(response.body).to eq('ok')
    end
  end
end
