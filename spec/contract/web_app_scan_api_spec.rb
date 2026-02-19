# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Web App Scan API Contract' do
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:valid_api_keys_header) { 'accessKey=test-access-key;secretKey=test-secret-key;' }
  let(:config_id) { 'cfg-abcd-1234-efgh-5678' }
  let(:tracking_id) { 'trk-1111-2222-3333-4444' }
  let(:scan_id) { 'scn-aaaa-bbbb-cccc-dddd' }

  let(:conn) do
    Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  describe 'POST /was/v2/configs' do
    before do
      stub_request(:post, "#{base_url}/was/v2/configs")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 202,
          headers: {
            'Content-Type' => 'application/json',
            'Location' => "/was/v2/configs/#{config_id}"
          },
          body: ''
        )
    end

    it 'returns 202 with a Location header' do
      response = conn.post('/was/v2/configs') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = {
          'name' => 'My Web App Scan',
          'target' => 'https://example.com'
        }
      end

      expect(response.status).to eq(202)
      expect(response.headers['location']).to eq("/was/v2/configs/#{config_id}")
    end

    it 'includes the config id in the Location header path' do
      response = conn.post('/was/v2/configs') do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = {
          'name' => 'My Web App Scan',
          'target' => 'https://example.com'
        }
      end

      location = response.headers['location']
      expect(location).to include(config_id)
      expect(location).to match(%r{/was/v2/configs/.+})
    end
  end

  describe 'GET /was/v2/configs/{id}/status/{tracking_id}' do
    let(:status_response_body) do
      { 'status' => 'completed' }
    end

    before do
      stub_request(:get, "#{base_url}/was/v2/configs/#{config_id}/status/#{tracking_id}")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: status_response_body.to_json
        )
    end

    it 'returns 200 with a status field' do
      response = conn.get("/was/v2/configs/#{config_id}/status/#{tracking_id}") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('status')
      expect(response.body['status']).to be_a(String)
    end

    it 'returns completed as the status value' do
      response = conn.get("/was/v2/configs/#{config_id}/status/#{tracking_id}") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.body['status']).to eq('completed')
    end
  end

  describe 'POST /was/v2/configs/{id}/scans' do
    let(:scan_response_body) do
      { 'scan_id' => scan_id }
    end

    before do
      stub_request(:post, "#{base_url}/was/v2/configs/#{config_id}/scans")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: scan_response_body.to_json
        )
    end

    it 'returns 200 with a scan_id' do
      response = conn.post("/was/v2/configs/#{config_id}/scans") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('scan_id')
      expect(response.body['scan_id']).to be_a(String)
      expect(response.body['scan_id']).to eq(scan_id)
    end
  end

  describe 'POST /was/v2/configs/{id}/scans/search' do
    let(:search_response_body) do
      {
        'pagination' => {
          'total' => 25,
          'offset' => 0,
          'limit' => 10
        },
        'items' => [
          {
            'scan_id' => 'scn-1111-aaaa',
            'status' => 'completed',
            'started_at' => '2026-02-01T10:00:00Z',
            'finished_at' => '2026-02-01T10:30:00Z'
          },
          {
            'scan_id' => 'scn-2222-bbbb',
            'status' => 'completed',
            'started_at' => '2026-02-10T14:00:00Z',
            'finished_at' => '2026-02-10T14:45:00Z'
          }
        ]
      }
    end

    before do
      stub_request(:post, "#{base_url}/was/v2/configs/#{config_id}/scans/search")
        .with(headers: { 'X-ApiKeys' => valid_api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: search_response_body.to_json
        )
    end

    it 'returns 200 with pagination and items' do
      response = conn.post("/was/v2/configs/#{config_id}/scans/search") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = { 'offset' => 0, 'limit' => 10 }
      end

      expect(response.status).to eq(200)
      expect(response.body).to have_key('pagination')
      expect(response.body).to have_key('items')
    end

    it 'returns a pagination object with total, offset, and limit' do
      response = conn.post("/was/v2/configs/#{config_id}/scans/search") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = { 'offset' => 0, 'limit' => 10 }
      end

      pagination = response.body['pagination']
      expect(pagination).to be_a(Hash)
      expect(pagination).to have_key('total')
      expect(pagination).to have_key('offset')
      expect(pagination).to have_key('limit')
      expect(pagination['total']).to be_a(Integer)
      expect(pagination['offset']).to be_a(Integer)
      expect(pagination['limit']).to be_a(Integer)
    end

    it 'returns items as an array of scan records' do
      response = conn.post("/was/v2/configs/#{config_id}/scans/search") do |req|
        req.headers['X-ApiKeys'] = valid_api_keys_header
        req.body = { 'offset' => 0, 'limit' => 10 }
      end

      items = response.body['items']
      expect(items).to be_an(Array)
      expect(items.length).to eq(2)

      items.each do |item|
        expect(item).to have_key('scan_id')
        expect(item).to have_key('status')
      end
    end
  end
end
