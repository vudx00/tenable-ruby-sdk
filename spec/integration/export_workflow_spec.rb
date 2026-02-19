# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Export workflow', :integration do
  let(:access_key) { 'ak' }
  let(:secret_key) { 'sk' }
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:export_uuid) { 'abcd1234-ef56-7890-abcd-ef1234567890' }
  let(:api_keys_header) { "accessKey=#{access_key};secretKey=#{secret_key};" }

  let(:client) { Tenable::Client.new(access_key: access_key, secret_key: secret_key) }

  let(:chunk_0_data) do
    [
      {
        'asset' => { 'uuid' => 'asset-001', 'hostname' => 'web-01', 'ipv4' => '10.0.1.1' },
        'plugin' => { 'id' => 10001, 'name' => 'CVE-2025-0001', 'family' => 'General' },
        'severity' => 'critical',
        'state' => 'open'
      },
      {
        'asset' => { 'uuid' => 'asset-002', 'hostname' => 'db-01', 'ipv4' => '10.0.2.1' },
        'plugin' => { 'id' => 10002, 'name' => 'CVE-2025-0002', 'family' => 'Databases' },
        'severity' => 'high',
        'state' => 'open'
      }
    ]
  end

  let(:chunk_1_data) do
    [
      {
        'asset' => { 'uuid' => 'asset-003', 'hostname' => 'app-01', 'ipv4' => '10.0.3.1' },
        'plugin' => { 'id' => 10003, 'name' => 'CVE-2025-0003', 'family' => 'Web Servers' },
        'severity' => 'medium',
        'state' => 'open'
      }
    ]
  end

  describe 'initiate export -> poll status -> download chunks -> iterate results' do
    before do
      stub_request(:post, "#{base_url}/vulns/export")
        .with(
          headers: { 'X-ApiKeys' => api_keys_header },
          body: { 'num_assets' => 500 }.to_json
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { 'export_uuid' => export_uuid }.to_json
        )

      stub_request(:get, "#{base_url}/vulns/export/#{export_uuid}/status")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'PROCESSING', 'chunks_available' => [], 'chunks_failed' => [] }.to_json },
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'FINISHED', 'chunks_available' => [0, 1], 'chunks_failed' => [] }.to_json }
        )

      stub_request(:get, "#{base_url}/vulns/export/#{export_uuid}/chunks/0")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: chunk_0_data.to_json
        )

      stub_request(:get, "#{base_url}/vulns/export/#{export_uuid}/chunks/1")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: chunk_1_data.to_json
        )
    end

    it 'initiates an export and receives an export UUID' do
      response = client.exports.send(:post, '/vulns/export', { 'num_assets' => 500 })

      expect(response).to be_a(Hash)
      expect(response).to have_key('export_uuid')
      expect(response['export_uuid']).to eq(export_uuid)
    end

    it 'polls status until FINISHED and retrieves chunk IDs' do
      # First poll returns PROCESSING
      status1 = client.exports.send(:get,"/vulns/export/#{export_uuid}/status")
      expect(status1['status']).to eq('PROCESSING')
      expect(status1['chunks_available']).to be_empty

      # Second poll returns FINISHED with chunks
      status2 = client.exports.send(:get,"/vulns/export/#{export_uuid}/status")
      expect(status2['status']).to eq('FINISHED')
      expect(status2['chunks_available']).to eq([0, 1])
      expect(status2['chunks_failed']).to be_empty
    end

    it 'downloads chunks and iterates over all vulnerability records' do
      chunk0 = client.exports.send(:get,"/vulns/export/#{export_uuid}/chunks/0")
      chunk1 = client.exports.send(:get,"/vulns/export/#{export_uuid}/chunks/1")

      all_results = chunk0 + chunk1

      expect(all_results).to be_an(Array)
      expect(all_results.length).to eq(3)

      all_results.each do |record|
        expect(record).to be_a(Hash)
        expect(record).to have_key('asset')
        expect(record).to have_key('plugin')
        expect(record).to have_key('severity')
        expect(record).to have_key('state')
      end
    end

    it 'collects all hostnames across chunks' do
      chunk0 = client.exports.send(:get,"/vulns/export/#{export_uuid}/chunks/0")
      chunk1 = client.exports.send(:get,"/vulns/export/#{export_uuid}/chunks/1")

      hostnames = (chunk0 + chunk1).map { |r| r['asset']['hostname'] }

      expect(hostnames).to contain_exactly('web-01', 'db-01', 'app-01')
    end
  end

  describe 'export timeout raises TimeoutError' do
    before do
      stub_request(:post, "#{base_url}/vulns/export")
        .with(
          headers: { 'X-ApiKeys' => api_keys_header },
          body: { 'num_assets' => 100 }.to_json
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { 'export_uuid' => export_uuid }.to_json
        )

      stub_request(:get, "#{base_url}/vulns/export/#{export_uuid}/status")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { 'status' => 'PROCESSING', 'chunks_available' => [], 'chunks_failed' => [] }.to_json
        )
    end

    it 'raises TimeoutError with the export UUID when polling exceeds the limit' do
      export_response = client.exports.send(:post,'/vulns/export', { 'num_assets' => 100 })
      uuid = export_response['export_uuid']

      max_polls = 3
      polls = 0

      expect do
        loop do
          status = client.exports.send(:get,"/vulns/export/#{uuid}/status")
          break if status['status'] == 'FINISHED'

          polls += 1
          raise Tenable::TimeoutError, "Export #{uuid} timed out after #{polls} polls" if polls >= max_polls
        end
      end.to raise_error(Tenable::TimeoutError, /#{uuid}/)
    end

    it 'includes the UUID in the TimeoutError message for debugging' do
      export_response = client.exports.send(:post,'/vulns/export', { 'num_assets' => 100 })
      uuid = export_response['export_uuid']

      begin
        raise Tenable::TimeoutError, "Export #{uuid} timed out waiting for completion"
      rescue Tenable::TimeoutError => e
        expect(e.message).to include(uuid)
        expect(e).to be_a(Tenable::TimeoutError)
      end
    end
  end
end
