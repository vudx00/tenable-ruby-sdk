# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Authentication workflow', :integration do
  let(:access_key) { 'test-access-key' }
  let(:secret_key) { 'test-secret-key' }
  let(:base_url) { 'https://cloud.tenable.com' }

  after do
    ENV.delete('TENABLE_ACCESS_KEY')
    ENV.delete('TENABLE_SECRET_KEY')
  end

  describe 'full client creation -> authenticated request -> successful response' do
    it 'includes X-ApiKeys header with valid credentials' do
      stub_request(:get, "#{base_url}/workbenches/vulnerabilities")
        .with(headers: { 'X-ApiKeys' => "accessKey=#{access_key};secretKey=#{secret_key};" })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: '{"vulnerabilities":[]}'
        )

      client = Tenable::Client.new(access_key: access_key, secret_key: secret_key)
      response = client.vulnerabilities.list

      expect(response).to be_a(Hash)
      expect(response).to have_key('vulnerabilities')
    end
  end

  describe 'invalid credentials -> AuthenticationError' do
    it 'raises Tenable::AuthenticationError on 401 response' do
      stub_request(:get, "#{base_url}/workbenches/vulnerabilities")
        .to_return(
          status: 401,
          headers: { 'Content-Type' => 'application/json' },
          body: '{"statusCode":401,"error":"Unauthorized","message":"Invalid Credentials"}'
        )

      client = Tenable::Client.new(access_key: access_key, secret_key: secret_key)

      expect { client.vulnerabilities.list }.to raise_error(Tenable::AuthenticationError)
    end
  end

  describe 'missing credentials -> configuration error' do
    it 'raises ArgumentError when no keys are provided and env vars are unset' do
      ENV.delete('TENABLE_ACCESS_KEY')
      ENV.delete('TENABLE_SECRET_KEY')

      expect { Tenable::Client.new }.to raise_error(ArgumentError, /access_key|TENABLE_ACCESS_KEY/)
    end
  end
end
