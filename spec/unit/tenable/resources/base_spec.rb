# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Resources::Base do
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

  let(:connection) { Tenable::Connection.new(config) }

  # Use a concrete subclass to test private methods via public wrappers
  let(:resource_class) do
    Class.new(described_class) do
      def do_put(path, body = nil)
        put(path, body)
      end

      def do_patch(path, body = nil)
        patch(path, body)
      end

      def do_delete(path, params = {})
        delete(path, params)
      end
    end
  end

  let(:resource) { resource_class.new(connection) }

  describe '#put' do
    let(:response_body) { { 'id' => 1, 'updated' => true } }

    before do
      stub_request(:put, 'https://cloud.tenable.com/test/1')
        .with(
          body: JSON.generate({ name: 'updated' }),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a PUT request with JSON body' do
      resource.do_put('/test/1', { name: 'updated' })

      expect(WebMock).to have_requested(:put, 'https://cloud.tenable.com/test/1')
        .with(body: JSON.generate({ name: 'updated' }))
    end

    it 'returns parsed JSON response' do
      result = resource.do_put('/test/1', { name: 'updated' })

      expect(result).to eq(response_body)
    end

    it 'sends a PUT request without body when nil' do
      stub_request(:put, 'https://cloud.tenable.com/test/1')
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })

      resource.do_put('/test/1')

      expect(WebMock).to have_requested(:put, 'https://cloud.tenable.com/test/1')
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:put, 'https://cloud.tenable.com/test/1')
        .to_return(status: 401, body: 'Unauthorized')

      expect { resource.do_put('/test/1', { name: 'updated' }) }
        .to raise_error(Tenable::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:put, 'https://cloud.tenable.com/test/1')
        .to_return(status: 429, body: 'Rate limited')

      expect { resource.do_put('/test/1', { name: 'updated' }) }
        .to raise_error(Tenable::RateLimitError)
    end

    it 'raises ApiError on other non-2xx responses' do
      stub_request(:put, 'https://cloud.tenable.com/test/1')
        .to_return(status: 500, body: 'Internal Server Error')

      expect { resource.do_put('/test/1', { name: 'updated' }) }
        .to raise_error(Tenable::ApiError)
    end
  end

  describe '#patch' do
    let(:response_body) { { 'id' => 1, 'status' => 'stopped' } }

    before do
      stub_request(:patch, 'https://cloud.tenable.com/test/1')
        .with(
          body: JSON.generate({ status: 'stopped' }),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a PATCH request with JSON body' do
      resource.do_patch('/test/1', { status: 'stopped' })

      expect(WebMock).to have_requested(:patch, 'https://cloud.tenable.com/test/1')
        .with(body: JSON.generate({ status: 'stopped' }))
    end

    it 'returns parsed JSON response' do
      result = resource.do_patch('/test/1', { status: 'stopped' })

      expect(result).to eq(response_body)
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:patch, 'https://cloud.tenable.com/test/1')
        .to_return(status: 401, body: 'Unauthorized')

      expect { resource.do_patch('/test/1', { status: 'stopped' }) }
        .to raise_error(Tenable::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:patch, 'https://cloud.tenable.com/test/1')
        .to_return(status: 429, body: 'Rate limited')

      expect { resource.do_patch('/test/1', { status: 'stopped' }) }
        .to raise_error(Tenable::RateLimitError)
    end

    it 'raises ApiError on other non-2xx responses' do
      stub_request(:patch, 'https://cloud.tenable.com/test/1')
        .to_return(status: 500, body: 'Internal Server Error')

      expect { resource.do_patch('/test/1', { status: 'stopped' }) }
        .to raise_error(Tenable::ApiError)
    end
  end

  describe '#delete' do
    before do
      stub_request(:delete, 'https://cloud.tenable.com/test/1')
        .to_return(
          status: 200,
          body: '',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a DELETE request' do
      resource.do_delete('/test/1')

      expect(WebMock).to have_requested(:delete, 'https://cloud.tenable.com/test/1')
    end

    it 'returns nil for empty response body' do
      result = resource.do_delete('/test/1')

      expect(result).to be_nil
    end

    it 'returns parsed JSON when response has a body' do
      stub_request(:delete, 'https://cloud.tenable.com/test/1')
        .to_return(
          status: 200,
          body: JSON.generate({ 'deleted' => true }),
          headers: { 'Content-Type' => 'application/json' }
        )

      result = resource.do_delete('/test/1')

      expect(result).to eq({ 'deleted' => true })
    end

    it 'raises AuthenticationError on 401' do
      stub_request(:delete, 'https://cloud.tenable.com/test/1')
        .to_return(status: 401, body: 'Unauthorized')

      expect { resource.do_delete('/test/1') }
        .to raise_error(Tenable::AuthenticationError)
    end

    it 'raises RateLimitError on 429' do
      stub_request(:delete, 'https://cloud.tenable.com/test/1')
        .to_return(status: 429, body: 'Rate limited')

      expect { resource.do_delete('/test/1') }
        .to raise_error(Tenable::RateLimitError)
    end

    it 'raises ApiError on other non-2xx responses' do
      stub_request(:delete, 'https://cloud.tenable.com/test/1')
        .to_return(status: 500, body: 'Internal Server Error')

      expect { resource.do_delete('/test/1') }
        .to raise_error(Tenable::ApiError)
    end
  end

  describe '#validate_path_segment!' do
    let(:resource_with_validation) do
      Class.new(described_class) do
        def check_segment(value, name: 'id')
          validate_path_segment!(value, name: name)
        end
      end
    end

    let(:validator) { resource_with_validation.new(connection) }

    it 'accepts a simple string ID' do
      expect { validator.check_segment('abc-123') }.not_to raise_error
    end

    it 'accepts an integer ID' do
      expect { validator.check_segment(42) }.not_to raise_error
    end

    it 'rejects IDs containing /' do
      expect { validator.check_segment('abc/def') }
        .to raise_error(ArgumentError, /unsafe characters/)
    end

    it 'rejects IDs containing ..' do
      expect { validator.check_segment('../evil') }
        .to raise_error(ArgumentError, /unsafe characters/)
    end

    it 'rejects empty strings' do
      expect { validator.check_segment('') }
        .to raise_error(ArgumentError, /unsafe characters/)
    end

    it 'includes the parameter name in the error message' do
      expect { validator.check_segment('../evil', name: 'scan_id') }
        .to raise_error(ArgumentError, /scan_id/)
    end
  end
end
