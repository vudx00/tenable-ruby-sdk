# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'WAS export workflow', :integration do
  let(:access_key) { 'ak' }
  let(:secret_key) { 'sk' }
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:scan_id) { 'scan-xyz-789' }
  let(:api_keys_header) { "accessKey=#{access_key};secretKey=#{secret_key};" }
  let(:binary_content) { "\x50\x4B\x03\x04 fake export content" }

  let(:client) { Tenable::Client.new(access_key: access_key, secret_key: secret_key) }

  describe 'per-scan export flow' do
    before do
      stub_request(:put, "#{base_url}/was/v2/scans/#{scan_id}/export")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate({ 'scan_id' => scan_id, 'status' => 'exporting' })
        )

      stub_request(:get, "#{base_url}/was/v2/scans/#{scan_id}/export/download")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/octet-stream' },
          body: binary_content
        )
    end

    it 'initiates an export and downloads the result' do
      result = client.web_app_scans.export_scan(scan_id)
      expect(result['status']).to eq('exporting')

      content = client.web_app_scans.download_scan_export(scan_id)
      expect(content).to be_a(String)
      expect(content).to eq(binary_content)

      expect(WebMock).to have_requested(:put, "#{base_url}/was/v2/scans/#{scan_id}/export").once
      expect(WebMock).to have_requested(:get, "#{base_url}/was/v2/scans/#{scan_id}/export/download").once
    end
  end

  describe 'bulk findings export flow' do
    let(:export_uuid) { 'exp-abc-123' }
    let(:chunk_data) do
      [
        { 'vuln_id' => 'v-001', 'name' => 'SQL Injection', 'severity' => 'high' },
        { 'vuln_id' => 'v-002', 'name' => 'XSS', 'severity' => 'medium' }
      ]
    end

    before do
      stub_request(:post, "#{base_url}/was/v1/export/vulns")
        .with(headers: { 'X-ApiKeys' => api_keys_header, 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate({ 'export_uuid' => export_uuid })
        )

      stub_request(:get, "#{base_url}/was/v1/export/vulns/#{export_uuid}/status")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate({ 'status' => 'FINISHED', 'chunks_available' => [0] })
        )

      stub_request(:get, "#{base_url}/was/v1/export/vulns/#{export_uuid}/chunks/0")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate(chunk_data)
        )
    end

    it 'initiates export, checks status, and downloads chunk data' do
      was = client.web_app_scans

      result = was.export_findings(severity: 'high')
      expect(result['export_uuid']).to eq(export_uuid)

      status = was.export_findings_status(export_uuid)
      expect(status['status']).to eq('FINISHED')
      expect(status['chunks_available']).to eq([0])

      chunk = was.export_findings_chunk(export_uuid, 0)
      expect(chunk).to be_an(Array)
      expect(chunk.length).to eq(2)
      expect(chunk.first['name']).to eq('SQL Injection')
    end
  end
end
