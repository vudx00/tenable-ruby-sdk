# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Scan API Contract' do
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:valid_api_keys_header) { 'accessKey=test-access-key;secretKey=test-secret-key;' }
  let(:scan_id) { 42 }
  let(:scan_uuid) { 'abcd1234-ef56-7890-abcd-ef1234567890' }

  let(:conn) do
    Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  describe 'GET /scans' do
    let(:scans_response_body) do
      {
        'scans' => [
          {
            'id' => 1,
            'uuid' => 'aaa-bbb-ccc-111',
            'name' => 'Weekly Network Scan',
            'status' => 'completed'
          },
          {
            'id' => 2,
            'uuid' => 'ddd-eee-fff-222',
            'name' => 'Monthly Compliance Scan',
            'status' => 'running'
          }
        ]
      }
    end

    before do
      stub_request(:get, "#{base_url}/scans")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: scans_response_body.to_json
        )
    end

    it 'returns 200 with a scans array' do
      response = conn.get('/scans') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('scans')
      expect(response.body['scans']).to be_an(Array)
      expect(response.body['scans'].length).to eq(2)
    end

    it 'returns scans with id, uuid, name, and status fields' do
      response = conn.get('/scans') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      response.body['scans'].each do |scan|
        expect(scan).to have_key('id')
        expect(scan).to have_key('uuid')
        expect(scan).to have_key('name')
        expect(scan).to have_key('status')
      end
    end

    it 'returns numeric id and string values for uuid, name, and status' do
      response = conn.get('/scans') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      scan = response.body['scans'].first
      expect(scan['id']).to be_a(Integer)
      expect(scan['uuid']).to be_a(String)
      expect(scan['name']).to be_a(String)
      expect(scan['status']).to be_a(String)
    end
  end

  describe 'POST /scans' do
    let(:create_scan_response_body) do
      {
        'scan' => {
          'id' => scan_id,
          'uuid' => scan_uuid
        }
      }
    end

    before do
      stub_request(:post, "#{base_url}/scans")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: create_scan_response_body.to_json
        )
    end

    it 'returns 200 with a scan object containing id and uuid' do
      response = conn.post('/scans') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = { 'uuid' => 'template-uuid', 'settings' => { 'name' => 'New Scan', 'text_targets' => '10.0.0.1' } }
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('scan')
      expect(response.body['scan']).to be_a(Hash)
    end

    it 'returns a scan with a numeric id and string uuid' do
      response = conn.post('/scans') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = { 'uuid' => 'template-uuid', 'settings' => { 'name' => 'New Scan', 'text_targets' => '10.0.0.1' } }
      end

      scan = response.body['scan']
      expect(scan['id']).to be_a(Integer)
      expect(scan['id']).to eq(scan_id)
      expect(scan['uuid']).to be_a(String)
      expect(scan['uuid']).to eq(scan_uuid)
    end
  end

  describe 'POST /scans/{id}/launch' do
    let(:launch_response_body) do
      { 'scan_uuid' => scan_uuid }
    end

    before do
      stub_request(:post, "#{base_url}/scans/#{scan_id}/launch")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: launch_response_body.to_json
        )
    end

    it 'returns 200 with a scan_uuid' do
      response = conn.post("/scans/#{scan_id}/launch") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('scan_uuid')
      expect(response.body['scan_uuid']).to be_a(String)
      expect(response.body['scan_uuid']).to eq(scan_uuid)
    end
  end

  describe 'GET /scans/{id}/latest-status' do
    let(:status_response_body) do
      { 'status' => 'running' }
    end

    before do
      stub_request(:get, "#{base_url}/scans/#{scan_id}/latest-status")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: status_response_body.to_json
        )
    end

    it 'returns 200 with a status field' do
      response = conn.get("/scans/#{scan_id}/latest-status") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('status')
      expect(response.body['status']).to be_a(String)
    end

    it 'returns a recognized scan status value' do
      response = conn.get("/scans/#{scan_id}/latest-status") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.body['status']).to eq('running')
    end
  end
end
