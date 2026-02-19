# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Export API Contract' do
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:valid_api_keys_header) { 'accessKey=test-access-key;secretKey=test-secret-key;' }
  let(:export_uuid) { 'e1d2c3b4-a5f6-7890-abcd-ef1234567890' }

  let(:conn) do
    Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  describe 'POST /vulns/export' do
    let(:export_request_body) do
      {
        'num_assets' => 500,
        'filters' => {
          'severity' => ['critical', 'high']
        }
      }
    end

    let(:export_response_body) do
      { 'export_uuid' => export_uuid }
    end

    before do
      stub_request(:post, "#{base_url}/vulns/export")
        .with(
          headers: { 'X-ApiKeys' => valid_api_keys_header },
          body: export_request_body
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: export_response_body.to_json
        )
    end

    it 'accepts num_assets and filters in the request body' do
      response = conn.post('/vulns/export') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = export_request_body
      end

      expect(response.status).to eq(200)
    end

    it 'returns an export_uuid in the response' do
      response = conn.post('/vulns/export') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = export_request_body
      end

      expect(response.body).to have_key('export_uuid')
      expect(response.body['export_uuid']).to be_a(String)
      expect(response.body['export_uuid']).to eq(export_uuid)
    end
  end

  describe 'GET /vulns/export/{uuid}/status' do
    let(:status_response_body) do
      {
        'status' => 'FINISHED',
        'chunks_available' => [0, 1, 2],
        'chunks_failed' => [],
        'chunks_cancelled' => [],
        'total_chunks' => 3,
        'num_assets_per_chunk' => 500
      }
    end

    before do
      stub_request(:get, "#{base_url}/vulns/export/#{export_uuid}/status")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: status_response_body.to_json
        )
    end

    it 'returns status, chunks_available, and chunks_failed fields' do
      response = conn.get("/vulns/export/#{export_uuid}/status") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('status')
      expect(response.body['status']).to be_a(String)
      expect(response.body).to have_key('chunks_available')
      expect(response.body['chunks_available']).to be_an(Array)
      expect(response.body).to have_key('chunks_failed')
      expect(response.body['chunks_failed']).to be_an(Array)
    end

    it 'returns a recognized status value' do
      response = conn.get("/vulns/export/#{export_uuid}/status") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(%w[QUEUED PROCESSING FINISHED CANCELLED ERROR]).to include(response.body['status'])
    end

    it 'returns chunk identifiers as integers' do
      response = conn.get("/vulns/export/#{export_uuid}/status") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      response.body['chunks_available'].each do |chunk_id|
        expect(chunk_id).to be_a(Integer)
      end
    end
  end

  describe 'GET /vulns/export/{uuid}/chunks/{id}' do
    let(:chunk_id) { 0 }

    let(:chunk_response_body) do
      [
        {
          'asset' => {
            'uuid' => 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
            'hostname' => 'web-server-01',
            'ipv4' => '10.0.1.100',
            'operating_system' => ['Linux']
          },
          'plugin' => {
            'id' => 12345,
            'name' => 'SSL Certificate Expired',
            'family' => 'General'
          },
          'severity' => 'critical',
          'state' => 'open',
          'first_found' => '2025-12-01T00:00:00Z',
          'last_found' => '2026-02-19T00:00:00Z'
        },
        {
          'asset' => {
            'uuid' => 'b2c3d4e5-f6a7-8901-bcde-f12345678901',
            'hostname' => 'db-server-02',
            'ipv4' => '10.0.2.50',
            'operating_system' => ['Windows Server 2022']
          },
          'plugin' => {
            'id' => 67890,
            'name' => 'Remote Code Execution',
            'family' => 'Windows'
          },
          'severity' => 'high',
          'state' => 'open',
          'first_found' => '2026-01-15T00:00:00Z',
          'last_found' => '2026-02-19T00:00:00Z'
        }
      ]
    end

    before do
      stub_request(:get, "#{base_url}/vulns/export/#{export_uuid}/chunks/#{chunk_id}")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: chunk_response_body.to_json
        )
    end

    it 'returns a JSON array of vulnerability records' do
      response = conn.get("/vulns/export/#{export_uuid}/chunks/#{chunk_id}") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to be_an(Array)
      expect(response.body.length).to eq(2)
    end

    it 'returns vulnerability records with asset data' do
      response = conn.get("/vulns/export/#{export_uuid}/chunks/#{chunk_id}") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      record = response.body.first
      expect(record).to have_key('asset')
      expect(record['asset']).to be_a(Hash)
      expect(record['asset']).to have_key('uuid')
      expect(record['asset']).to have_key('hostname')
    end

    it 'returns vulnerability records with plugin data' do
      response = conn.get("/vulns/export/#{export_uuid}/chunks/#{chunk_id}") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      record = response.body.first
      expect(record).to have_key('plugin')
      expect(record['plugin']).to be_a(Hash)
      expect(record['plugin']).to have_key('id')
      expect(record['plugin']).to have_key('name')
      expect(record['plugin']).to have_key('family')
    end

    it 'returns vulnerability records with severity and state fields' do
      response = conn.get("/vulns/export/#{export_uuid}/chunks/#{chunk_id}") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      response.body.each do |record|
        expect(record).to have_key('severity')
        expect(record['severity']).to be_a(String)
        expect(record).to have_key('state')
        expect(record['state']).to be_a(String)
      end
    end
  end
end
