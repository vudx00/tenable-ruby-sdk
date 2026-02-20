# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Client do
  # Helper to temporarily set ENV vars and guarantee cleanup
  def with_env(vars)
    original = vars.each_key.to_h { |k| [k, ENV.fetch(k, nil)] }
    vars.each { |k, v| ENV[k] = v }
    yield
  ensure
    original.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
  end

  describe 'initialization' do
    context 'with direct keys' do
      subject(:client) { described_class.new(access_key: 'ak_direct', secret_key: 'sk_direct') }

      it 'creates a client successfully' do
        expect(client).to be_a(described_class)
      end
    end

    context 'from environment variables' do
      it 'creates a client successfully' do
        with_env('TENABLE_ACCESS_KEY' => 'ak_env', 'TENABLE_SECRET_KEY' => 'sk_env') do
          client = described_class.new
          expect(client).to be_a(described_class)
        end
      end
    end

    context 'with missing credentials' do
      it 'raises an ArgumentError when no keys are provided' do
        expect { described_class.new }.to raise_error(ArgumentError)
      end

      it 'raises an ArgumentError when only access_key is provided' do
        expect { described_class.new(access_key: 'ak_only') }.to raise_error(ArgumentError)
      end

      it 'raises an ArgumentError when only secret_key is provided' do
        expect { described_class.new(secret_key: 'sk_only') }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'resource accessors' do
    subject(:client) { described_class.new(access_key: 'ak_test', secret_key: 'sk_test') }

    it 'returns a Vulnerabilities resource' do
      expect(client.vulnerabilities).to be_a(Tenable::Resources::Vulnerabilities)
    end

    it 'returns an Exports resource' do
      expect(client.exports).to be_a(Tenable::Resources::Exports)
    end

    it 'returns an AssetExports resource' do
      expect(client.asset_exports).to be_a(Tenable::Resources::AssetExports)
    end

    it 'returns a Scans resource' do
      expect(client.scans).to be_a(Tenable::Resources::Scans)
    end

    it 'returns a WebAppScans resource' do
      expect(client.web_app_scans).to be_a(Tenable::Resources::WebAppScans)
    end

    it 'returns the same Vulnerabilities instance on repeated calls' do
      expect(client.vulnerabilities).to equal(client.vulnerabilities)
    end
  end

  describe 'thread safety' do
    subject(:client) { described_class.new(access_key: 'ak_frozen', secret_key: 'sk_frozen') }

    it 'is frozen after initialization' do
      expect(client).to be_frozen
    end

    it 'cannot set instance variables after initialization' do
      expect { client.instance_variable_set(:@config, nil) }.to raise_error(FrozenError)
    end
  end

  describe 'logger configuration' do
    it 'passes a custom logger through to the configuration' do
      custom_logger = Logger.new($stdout)
      client = described_class.new(access_key: 'ak_log', secret_key: 'sk_log', logger: custom_logger)

      expect(client.configuration.logger).to eq(custom_logger)
    end
  end

  describe 'custom base_url and timeout configuration' do
    subject(:client) do
      described_class.new(
        access_key: 'ak_custom',
        secret_key: 'sk_custom',
        base_url: 'https://custom.tenable.com',
        timeout: 60
      )
    end

    it 'uses the custom base_url' do
      expect(client.configuration.base_url).to eq('https://custom.tenable.com')
    end

    it 'uses the custom timeout' do
      expect(client.configuration.timeout).to eq(60)
    end
  end
end
