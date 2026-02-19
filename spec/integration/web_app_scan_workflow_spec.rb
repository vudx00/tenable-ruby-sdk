# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Web App Scan workflow', :integration do
  let(:access_key) { 'ak' }
  let(:secret_key) { 'sk' }
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:api_keys_header) { "accessKey=#{access_key};secretKey=#{secret_key};" }
  let(:config_id) { 'cfg-abcd-1234-efgh-5678' }
  let(:tracking_id) { 'trk-1111-2222-3333-4444' }
  let(:scan_id) { 'scn-aaaa-bbbb-cccc-dddd' }

  let(:client) { Tenable::Client.new(access_key: access_key, secret_key: secret_key) }

  describe 'create config -> launch scan -> poll status -> retrieve findings' do
    before do
      # Step 1: Create a web app scan config
      stub_request(:post, "#{base_url}/was/v2/configs")
        .with(
          headers: { 'X-ApiKeys' => api_keys_header },
          body: { 'name' => 'Integration Test Scan', 'target' => 'https://example.com' }.to_json
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { 'config_id' => config_id, 'tracking_id' => tracking_id }.to_json
        )

      # Step 2: Launch a scan against the config
      stub_request(:post, "#{base_url}/was/v2/configs/#{config_id}/scans")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { 'scan_id' => scan_id }.to_json
        )

      # Step 3: Poll config status - first pending, then completed
      stub_request(:get, "#{base_url}/was/v2/configs/#{config_id}/status/#{tracking_id}")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'pending' }.to_json },
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'processing' }.to_json },
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'completed' }.to_json }
        )

      # Step 4: Search for scan findings
      stub_request(:post, "#{base_url}/was/v2/configs/#{config_id}/scans/search")
        .with(
          headers: { 'X-ApiKeys' => api_keys_header },
          body: { 'offset' => 0, 'limit' => 50 }.to_json
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            'pagination' => { 'total' => 2, 'offset' => 0, 'limit' => 50 },
            'items' => [
              {
                'scan_id' => scan_id,
                'status' => 'completed',
                'started_at' => '2026-02-19T10:00:00Z',
                'finished_at' => '2026-02-19T10:30:00Z',
                'findings_count' => 5
              },
              {
                'scan_id' => 'scn-prev-scan-0001',
                'status' => 'completed',
                'started_at' => '2026-02-18T08:00:00Z',
                'finished_at' => '2026-02-18T08:20:00Z',
                'findings_count' => 3
              }
            ]
          }.to_json
        )
    end

    it 'creates a config and receives a config_id and tracking_id' do
      response = client.web_app_scans.send(
        :post,
        '/was/v2/configs',
        { 'name' => 'Integration Test Scan', 'target' => 'https://example.com' }
      )

      expect(response).to be_a(Hash)
      expect(response).to have_key('config_id')
      expect(response['config_id']).to eq(config_id)
      expect(response).to have_key('tracking_id')
      expect(response['tracking_id']).to eq(tracking_id)
    end

    it 'launches a scan against the config' do
      response = client.web_app_scans.send(
        :post,
        "/was/v2/configs/#{config_id}/scans"
      )

      expect(response).to be_a(Hash)
      expect(response).to have_key('scan_id')
      expect(response['scan_id']).to eq(scan_id)
    end

    it 'polls status until completed' do
      status1 = client.web_app_scans.send(
        :get,
        "/was/v2/configs/#{config_id}/status/#{tracking_id}"
      )
      expect(status1['status']).to eq('pending')

      status2 = client.web_app_scans.send(
        :get,
        "/was/v2/configs/#{config_id}/status/#{tracking_id}"
      )
      expect(status2['status']).to eq('processing')

      status3 = client.web_app_scans.send(
        :get,
        "/was/v2/configs/#{config_id}/status/#{tracking_id}"
      )
      expect(status3['status']).to eq('completed')
    end

    it 'retrieves findings after scan completes' do
      response = client.web_app_scans.send(
        :post,
        "/was/v2/configs/#{config_id}/scans/search",
        { 'offset' => 0, 'limit' => 50 }
      )

      expect(response).to be_a(Hash)
      expect(response).to have_key('pagination')
      expect(response).to have_key('items')
      expect(response['items']).to be_an(Array)
      expect(response['items'].length).to eq(2)
    end

    it 'runs the full end-to-end workflow' do
      # Create config
      create_response = client.web_app_scans.send(
        :post,
        '/was/v2/configs',
        { 'name' => 'Integration Test Scan', 'target' => 'https://example.com' }
      )
      cfg_id = create_response['config_id']
      trk_id = create_response['tracking_id']

      expect(cfg_id).to eq(config_id)
      expect(trk_id).to eq(tracking_id)

      # Launch scan
      launch_response = client.web_app_scans.send(
        :post,
        "/was/v2/configs/#{cfg_id}/scans"
      )
      launched_scan_id = launch_response['scan_id']
      expect(launched_scan_id).to eq(scan_id)

      # Poll until completed
      final_status = nil
      3.times do
        status_response = client.web_app_scans.send(
          :get,
          "/was/v2/configs/#{cfg_id}/status/#{trk_id}"
        )
        final_status = status_response['status']
        break if final_status == 'completed'
      end
      expect(final_status).to eq('completed')

      # Retrieve findings
      findings_response = client.web_app_scans.send(
        :post,
        "/was/v2/configs/#{cfg_id}/scans/search",
        { 'offset' => 0, 'limit' => 50 }
      )

      expect(findings_response['pagination']['total']).to eq(2)
      scan_ids = findings_response['items'].map { |item| item['scan_id'] }
      expect(scan_ids).to include(launched_scan_id)
    end
  end
end
