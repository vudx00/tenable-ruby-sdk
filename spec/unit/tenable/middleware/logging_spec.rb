# frozen_string_literal: true

require 'spec_helper'
require 'logger'
require 'stringio'
require 'tenable/middleware/logging'

RSpec.describe Tenable::Middleware::Logging do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }

  let(:connection) do |example|
    test_logger = example.metadata[:silent] ? nil : logger

    Faraday.new(url: 'https://cloud.tenable.com') do |f|
      f.use described_class, logger: test_logger
      f.adapter :test, stubs
    end
  end

  after { stubs.verify_stubbed_calls }

  context 'when no logger is provided', :silent do
    it 'passes through without errors' do
      stubs.get('/test') { [200, {}, 'ok'] }

      response = connection.get('/test')

      expect(response.status).to eq(200)
      expect(response.body).to eq('ok')
    end
  end

  context 'when a logger is provided' do
    it 'logs the request method and URL at debug level' do
      stubs.get('/test') { [200, {}, 'ok'] }

      connection.get('/test')

      log_output.rewind
      log_contents = log_output.string

      expect(log_contents).to match(%r{DEBUG.*GET.*/test})
    end

    it 'logs the response status at debug level' do
      stubs.get('/test') { [200, {}, 'ok'] }

      connection.get('/test')

      log_output.rewind
      log_contents = log_output.string

      expect(log_contents).to match(/DEBUG.*200/)
    end

    it 'redacts API keys from log output' do
      stubs.get('/test') { [200, {}, 'ok'] }

      connection.get('/test') do |req|
        req.headers['X-ApiKeys'] = 'accessKey=SECRET;secretKey=TOPSECRET'
      end

      log_output.rewind
      log_contents = log_output.string

      expect(log_contents).not_to include('SECRET')
      expect(log_contents).not_to include('TOPSECRET')
      expect(log_contents).to include('[REDACTED]')
    end

    it 'logs errors at error level' do
      stubs.get('/test') { raise Faraday::ConnectionFailed, 'connection refused' }

      expect { connection.get('/test') }.to raise_error(Faraday::ConnectionFailed)

      log_output.rewind
      log_contents = log_output.string

      expect(log_contents).to match(/ERROR.*connection refused/)
    end
  end
end
