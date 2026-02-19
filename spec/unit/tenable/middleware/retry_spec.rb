# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Middleware::Retry do
  let(:request_count) { { count: 0 } }

  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  let(:connection) do
    Faraday.new do |f|
      f.use described_class
      f.adapter :test, stubs
    end
  end

  after { stubs.verify_stubbed_calls }

  describe 'retrying on HTTP 429 with Retry-After header' do
    it 'respects the Retry-After delay value' do
      sleep_values = []

      stubs.get('/test') do
        request_count[:count] += 1
        if request_count[:count] < 2
          [429, { 'Retry-After' => '2' }, 'Too Many Requests']
        else
          [200, {}, 'OK']
        end
      end

      allow_any_instance_of(described_class).to receive(:sleep) { |_inst, val| sleep_values << val }

      response = connection.get('/test')

      expect(response.status).to eq(200)
      expect(request_count[:count]).to eq(2)
      expect(sleep_values).to include(2)
    end
  end

  describe 'retrying on 5xx with exponential backoff' do
    it 'uses exponential backoff between retries' do
      sleep_values = []

      stubs.get('/test') do
        request_count[:count] += 1
        if request_count[:count] < 3
          [500, {}, 'Internal Server Error']
        else
          [200, {}, 'OK']
        end
      end

      allow_any_instance_of(described_class).to receive(:sleep) { |_inst, val| sleep_values << val }

      response = connection.get('/test')

      expect(response.status).to eq(200)
      expect(request_count[:count]).to eq(3)
      expect(sleep_values.length).to eq(2)
      expect(sleep_values[1]).to be > sleep_values[0]
    end
  end

  describe 'max 3 attempts total (1 initial + 2 retries)' do
    it 'raises after exhausting all attempts' do
      stubs.get('/test') do
        request_count[:count] += 1
        [500, {}, 'Internal Server Error']
      end

      allow_any_instance_of(described_class).to receive(:sleep)

      expect { connection.get('/test') }.to raise_error(Tenable::Error)
      expect(request_count[:count]).to eq(3)
    end
  end

  describe 'does NOT retry on 4xx (except 429)' do
    [400, 401, 403, 404, 422].each do |status_code|
      it "does not retry on HTTP #{status_code}" do
        stubs.get('/test') do
          request_count[:count] += 1
          [status_code, {}, 'Client Error']
        end

        begin
          connection.get('/test')
        rescue Tenable::Error
          # expected for some status codes
        end

        expect(request_count[:count]).to eq(1)
      end
    end
  end

  describe 'raises final error with attempt count after exhaustion' do
    it 'includes the attempt count in the error' do
      stubs.get('/test') do
        request_count[:count] += 1
        [503, {}, 'Service Unavailable']
      end

      allow_any_instance_of(described_class).to receive(:sleep)

      expect { connection.get('/test') }.to raise_error(Tenable::Error) do |error|
        expect(error.message).to match(/3|attempts|retries|exhausted/i)
      end
    end
  end

  describe 'successful retry returns the success response' do
    it 'returns the successful response after retries' do
      stubs.get('/test') do
        request_count[:count] += 1
        if request_count[:count] < 2
          [502, {}, 'Bad Gateway']
        else
          [200, { 'Content-Type' => 'application/json' }, '{"status":"ok"}']
        end
      end

      allow_any_instance_of(described_class).to receive(:sleep)

      response = connection.get('/test')

      expect(response.status).to eq(200)
      expect(response.body).to eq('{"status":"ok"}')
      expect(request_count[:count]).to eq(2)
    end
  end
end
