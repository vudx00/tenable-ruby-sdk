# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Connection do
  let(:config) do
    instance_double(
      Tenable::Configuration,
      access_key: 'test-access-key',
      secret_key: 'test-secret-key',
      base_url: 'https://cloud.tenable.com',
      timeout: 30,
      open_timeout: 10,
      max_retries: 3,
      logger: nil
    )
  end

  let(:connection) { described_class.new(config) }

  describe '#faraday' do
    subject(:faraday) { connection.faraday }

    it 'returns a Faraday::Connection object' do
      expect(faraday).to be_a(Faraday::Connection)
    end

    it 'configures the base URL from the configuration' do
      expect(faraday.url_prefix.to_s).to eq('https://cloud.tenable.com/')
    end

    it 'sets the timeout from the configuration' do
      expect(faraday.options.timeout).to eq(30)
    end

    it 'sets the open_timeout from the configuration' do
      expect(faraday.options.open_timeout).to eq(10)
    end

    it 'sets the Accept header to application/json' do
      expect(faraday.headers['Accept']).to eq('application/json')
    end
  end

  describe 'middleware stack' do
    subject(:handlers) { connection.faraday.builder.handlers }

    it 'includes authentication middleware' do
      expect(handlers).to include(Tenable::Middleware::Authentication)
    end

    it 'includes retry middleware' do
      expect(handlers).to include(Tenable::Middleware::Retry)
    end

    it 'includes logging middleware' do
      expect(handlers).to include(Tenable::Middleware::Logging)
    end
  end
end
