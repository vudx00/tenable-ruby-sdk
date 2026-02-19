# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Resources::Vulnerabilities do
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
  let(:resource) { described_class.new(connection) }

  describe '#list' do
    context 'with vulnerability results' do
      let(:response_body) do
        {
          'vulnerabilities' => [
            {
              'count' => 5,
              'plugin_family' => 'General',
              'plugin_id' => 19_506,
              'plugin_name' => 'Nessus Scan Information',
              'severity' => 0
            },
            {
              'count' => 3,
              'plugin_family' => 'Web Servers',
              'plugin_id' => 10_863,
              'plugin_name' => 'SSL Certificate Information',
              'severity' => 2
            }
          ]
        }
      end

      before do
        stub_request(:get, 'https://cloud.tenable.com/workbenches/vulnerabilities')
          .to_return(
            status: 200,
            body: JSON.generate(response_body),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a hash containing vulnerability data' do
        result = resource.list

        expect(result).to be_a(Hash)
        expect(result).to have_key('vulnerabilities')
      end

      it 'returns the expected number of vulnerabilities' do
        result = resource.list

        expect(result['vulnerabilities'].length).to eq(2)
      end

      it 'returns vulnerability objects with expected attributes' do
        result = resource.list

        vuln = result['vulnerabilities'].first
        expect(vuln['plugin_id']).to eq(19_506)
        expect(vuln['plugin_name']).to eq('Nessus Scan Information')
        expect(vuln['severity']).to eq(0)
      end
    end

    context 'with severity filter' do
      before do
        stub_request(:get, 'https://cloud.tenable.com/workbenches/vulnerabilities')
          .with(query: { 'severity' => %w[critical high] })
          .to_return(
            status: 200,
            body: JSON.generate({
                                  'vulnerabilities' => [
                                    {
                                      'count' => 1,
                                      'plugin_family' => 'General',
                                      'plugin_id' => 12_345,
                                      'plugin_name' => 'Critical Vulnerability',
                                      'severity' => 4
                                    }
                                  ]
                                }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'passes severity filter as query parameters' do
        result = resource.list(severity: %i[critical high])

        expect(result['vulnerabilities'].length).to eq(1)
        expect(result['vulnerabilities'].first['severity']).to eq(4)
      end
    end

    context 'with empty results' do
      before do
        stub_request(:get, 'https://cloud.tenable.com/workbenches/vulnerabilities')
          .to_return(
            status: 200,
            body: JSON.generate({ 'vulnerabilities' => [] }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns an empty vulnerabilities array' do
        result = resource.list

        expect(result['vulnerabilities']).to eq([])
      end

      it 'does not raise an error' do
        expect { resource.list }.not_to raise_error
      end
    end

    context 'when the API returns an error' do
      before do
        stub_request(:get, 'https://cloud.tenable.com/workbenches/vulnerabilities')
          .to_return(status: 401, body: 'Unauthorized')
      end

      it 'raises an AuthenticationError on 401' do
        expect { resource.list }.to raise_error(Tenable::AuthenticationError)
      end
    end
  end

  describe '#info' do
    let(:plugin_id) { 19_506 }
    let(:response_body) do
      { 'info' => { 'plugindescription' => { 'pluginname' => 'Nessus Scan Information' } } }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/workbenches/vulnerabilities/#{plugin_id}/info")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /workbenches/vulnerabilities/{plugin_id}/info' do
      resource.info(plugin_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/workbenches/vulnerabilities/#{plugin_id}/info")
    end

    it 'returns vulnerability info data' do
      result = resource.info(plugin_id)

      expect(result['info']).to be_a(Hash)
    end
  end

  describe '#outputs' do
    let(:plugin_id) { 19_506 }
    let(:response_body) do
      { 'outputs' => [{ 'plugin_output' => 'scan info output', 'states' => [{ 'name' => 'open' }] }] }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/workbenches/vulnerabilities/#{plugin_id}/outputs")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /workbenches/vulnerabilities/{plugin_id}/outputs' do
      resource.outputs(plugin_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/workbenches/vulnerabilities/#{plugin_id}/outputs")
    end

    it 'returns plugin output data' do
      result = resource.outputs(plugin_id)

      expect(result['outputs']).to be_an(Array)
    end
  end

  describe '#assets' do
    let(:response_body) do
      { 'assets' => [{ 'id' => 'asset-001', 'fqdn' => ['host1.example.com'] }] }
    end

    before do
      stub_request(:get, 'https://cloud.tenable.com/workbenches/assets')
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /workbenches/assets' do
      resource.assets

      expect(WebMock).to have_requested(:get, 'https://cloud.tenable.com/workbenches/assets')
    end

    it 'returns asset data' do
      result = resource.assets

      expect(result['assets']).to be_an(Array)
      expect(result['assets'].first['id']).to eq('asset-001')
    end
  end

  describe '#asset_info' do
    let(:asset_id) { 'asset-001' }
    let(:response_body) do
      { 'info' => { 'fqdn' => ['host1.example.com'], 'operating_system' => ['Linux'] } }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/workbenches/assets/#{asset_id}/info")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /workbenches/assets/{asset_id}/info' do
      resource.asset_info(asset_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/workbenches/assets/#{asset_id}/info")
    end

    it 'returns asset info data' do
      result = resource.asset_info(asset_id)

      expect(result['info']['fqdn']).to include('host1.example.com')
    end
  end

  describe '#asset_vulnerabilities' do
    let(:asset_id) { 'asset-001' }
    let(:response_body) do
      { 'vulnerabilities' => [{ 'plugin_id' => 19_506, 'severity' => 0 }] }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/workbenches/assets/#{asset_id}/vulnerabilities")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /workbenches/assets/{asset_id}/vulnerabilities' do
      resource.asset_vulnerabilities(asset_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/workbenches/assets/#{asset_id}/vulnerabilities")
    end

    it 'returns vulnerability data for the asset' do
      result = resource.asset_vulnerabilities(asset_id)

      expect(result['vulnerabilities']).to be_an(Array)
      expect(result['vulnerabilities'].first['plugin_id']).to eq(19_506)
    end
  end
end
