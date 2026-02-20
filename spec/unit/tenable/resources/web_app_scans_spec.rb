# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe Tenable::Resources::WebAppScans do
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

  describe '#create_config' do
    let(:name) { 'Production Web App Scan' }
    let(:target) { 'https://app.example.com' }
    let(:response_body) do
      {
        'config_id' => 'cfg-abc-123',
        'name' => name,
        'target' => target,
        'status' => 'created'
      }
    end

    before do
      stub_request(:post, 'https://cloud.tenable.com/was/v2/configs')
        .with(
          body: JSON.generate({ 'name' => name, 'target' => target }),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 202,
          body: JSON.generate(response_body),
          headers: {
            'Content-Type' => 'application/json',
            'Location' => '/was/v2/configs/cfg-abc-123'
          }
        )
    end

    it 'sends a POST request to /was/v2/configs' do
      resource.create_config(name: name, target: target)

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/was/v2/configs')
        .with(body: JSON.generate({ 'name' => name, 'target' => target }))
    end

    it 'returns a parsed hash with config data' do
      result = resource.create_config(name: name, target: target)

      expect(result).to be_a(Hash)
      expect(result['config_id']).to eq('cfg-abc-123')
      expect(result['name']).to eq(name)
      expect(result['target']).to eq(target)
    end
  end

  describe '#launch' do
    let(:config_id) { 'cfg-abc-123' }
    let(:response_body) do
      { 'scan_id' => 'scan-xyz-789' }
    end

    before do
      stub_request(:post, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans")
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to /was/v2/configs/{id}/scans' do
      resource.launch(config_id)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans")
    end

    it 'returns a parsed hash with scan_id' do
      result = resource.launch(config_id)

      expect(result).to be_a(Hash)
      expect(result['scan_id']).to eq('scan-xyz-789')
    end
  end

  describe '#status' do
    let(:config_id) { 'cfg-abc-123' }
    let(:scan_id) { 'scan-xyz-789' }
    let(:response_body) do
      {
        'scan_id' => scan_id,
        'config_id' => config_id,
        'status' => 'scanning',
        'started_at' => '2026-02-19T10:00:00Z'
      }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}")
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to /was/v2/configs/{config_id}/scans/{scan_id}' do
      resource.status(config_id, scan_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}")
    end

    it 'returns a parsed hash with scanning status' do
      result = resource.status(config_id, scan_id)

      expect(result).to be_a(Hash)
      expect(result['status']).to eq('scanning')
      expect(result['scan_id']).to eq(scan_id)
    end
  end

  describe '#search_scan_vulnerabilities' do
    let(:scan_id) { 'scan-xyz-789' }
    let(:response_body) do
      {
        'items' => [
          {
            'vuln_id' => 'v-001',
            'name' => 'SQL Injection',
            'severity' => 'high'
          },
          {
            'vuln_id' => 'v-002',
            'name' => 'Cross-Site Scripting',
            'severity' => 'medium'
          }
        ],
        'pagination' => {
          'total' => 15,
          'offset' => 0,
          'limit' => 2
        }
      }
    end

    before do
      stub_request(:post, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/vulnerabilities/search")
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to /was/v2/scans/{scan_id}/vulnerabilities/search' do
      resource.search_scan_vulnerabilities(scan_id, severity: 'high')

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/vulnerabilities/search")
    end

    it 'returns search results with items and pagination' do
      result = resource.search_scan_vulnerabilities(scan_id)

      expect(result).to be_a(Hash)
      expect(result['items']).to be_an(Array)
      expect(result['items'].length).to eq(2)
      expect(result['pagination']['total']).to eq(15)
    end

    it 'returns vulnerability objects with expected attributes' do
      result = resource.search_scan_vulnerabilities(scan_id)

      vuln = result['items'].first
      expect(vuln['vuln_id']).to eq('v-001')
      expect(vuln['name']).to eq('SQL Injection')
      expect(vuln['severity']).to eq('high')
    end
  end

  describe '#wait_until_complete' do
    let(:config_id) { 'cfg-abc-123' }
    let(:scan_id) { 'scan-xyz-789' }

    context 'when scan completes after polling' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}")
          .to_return(
            { status: 200, body: JSON.generate({ 'status' => 'scanning' }),
              headers: { 'Content-Type' => 'application/json' } },
            { status: 200, body: JSON.generate({ 'status' => 'scanning' }),
              headers: { 'Content-Type' => 'application/json' } },
            { status: 200, body: JSON.generate({ 'status' => 'completed' }),
              headers: { 'Content-Type' => 'application/json' } }
          )
      end

      it 'polls until the scan status is completed' do
        allow(resource).to receive(:sleep)
        result = resource.wait_until_complete(config_id, scan_id, timeout: 60, poll_interval: 0)

        expect(result['status']).to eq('completed')
        expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}").times(3)
      end
    end

    context 'when scan fails' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}")
          .to_return(
            { status: 200, body: JSON.generate({ 'status' => 'scanning' }),
              headers: { 'Content-Type' => 'application/json' } },
            { status: 200, body: JSON.generate({ 'status' => 'failed' }),
              headers: { 'Content-Type' => 'application/json' } }
          )
      end

      it 'returns when status is a terminal state' do
        allow(resource).to receive(:sleep)
        result = resource.wait_until_complete(config_id, scan_id, timeout: 60, poll_interval: 0)

        expect(result['status']).to eq('failed')
        expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}").times(2)
      end
    end

    context 'when scan times out' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}")
          .to_return(
            status: 200, body: JSON.generate({ 'status' => 'scanning' }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'raises TimeoutError' do
        expect { resource.wait_until_complete(config_id, scan_id, timeout: 0, poll_interval: 0) }
          .to raise_error(Tenable::TimeoutError, /timed out/)
      end
    end
  end

  describe '#get_config' do
    let(:config_id) { 'cfg-abc-123' }
    let(:response_body) do
      { 'config_id' => config_id, 'name' => 'My Config', 'target' => 'https://example.com' }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /was/v2/configs/{config_id}' do
      resource.get_config(config_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}")
    end

    it 'returns configuration data' do
      result = resource.get_config(config_id)

      expect(result['config_id']).to eq(config_id)
      expect(result['name']).to eq('My Config')
    end
  end

  describe '#update_config' do
    let(:config_id) { 'cfg-abc-123' }
    let(:params) { { 'name' => 'Updated Config', 'target' => 'https://new.example.com' } }
    let(:response_body) { { 'config_id' => config_id, 'name' => 'Updated Config' } }

    before do
      stub_request(:put, "https://cloud.tenable.com/was/v2/configs/#{config_id}")
        .with(body: JSON.generate(params), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a PUT request to /was/v2/configs/{config_id}' do
      resource.update_config(config_id, params)

      expect(WebMock).to have_requested(:put, "https://cloud.tenable.com/was/v2/configs/#{config_id}")
        .with(body: JSON.generate(params))
    end

    it 'returns the updated configuration' do
      result = resource.update_config(config_id, params)

      expect(result['name']).to eq('Updated Config')
    end
  end

  describe '#delete_config' do
    let(:config_id) { 'cfg-abc-123' }

    before do
      stub_request(:delete, "https://cloud.tenable.com/was/v2/configs/#{config_id}")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a DELETE request to /was/v2/configs/{config_id}' do
      resource.delete_config(config_id)

      expect(WebMock).to have_requested(:delete, "https://cloud.tenable.com/was/v2/configs/#{config_id}")
    end

    it 'returns nil for empty response' do
      result = resource.delete_config(config_id)

      expect(result).to be_nil
    end
  end

  describe '#search_configs' do
    let(:response_body) do
      {
        'items' => [{ 'config_id' => 'cfg-abc-123', 'name' => 'My Config' }],
        'pagination' => { 'total' => 1, 'offset' => 0, 'limit' => 50 }
      }
    end

    before do
      stub_request(:post, 'https://cloud.tenable.com/was/v2/configs/search')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /was/v2/configs/search' do
      resource.search_configs(filter: { name: 'My Config' })

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/was/v2/configs/search')
    end

    it 'returns search results with items and pagination' do
      result = resource.search_configs(filter: { name: 'My Config' })

      expect(result['items']).to be_an(Array)
      expect(result['pagination']['total']).to eq(1)
    end
  end

  describe '#get_scan' do
    let(:scan_id) { 'scan-xyz-789' }
    let(:response_body) do
      { 'scan_id' => scan_id, 'status' => 'completed', 'target' => 'https://example.com' }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /was/v2/scans/{scan_id}' do
      resource.get_scan(scan_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}")
    end

    it 'returns scan details' do
      result = resource.get_scan(scan_id)

      expect(result['scan_id']).to eq(scan_id)
      expect(result['status']).to eq('completed')
    end
  end

  describe '#stop_scan' do
    let(:scan_id) { 'scan-xyz-789' }
    let(:response_body) { { 'scan_id' => scan_id, 'status' => 'stopped' } }

    before do
      stub_request(:patch, "https://cloud.tenable.com/was/v2/scans/#{scan_id}")
        .with(body: JSON.generate({ 'requested_action' => 'stop' }), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a PATCH request with stop action' do
      resource.stop_scan(scan_id)

      expect(WebMock).to have_requested(:patch, "https://cloud.tenable.com/was/v2/scans/#{scan_id}")
        .with(body: JSON.generate({ 'requested_action' => 'stop' }))
    end

    it 'returns the updated status' do
      result = resource.stop_scan(scan_id)

      expect(result['status']).to eq('stopped')
    end
  end

  describe '#delete_scan' do
    let(:scan_id) { 'scan-xyz-789' }

    before do
      stub_request(:delete, "https://cloud.tenable.com/was/v2/scans/#{scan_id}")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a DELETE request to /was/v2/scans/{scan_id}' do
      resource.delete_scan(scan_id)

      expect(WebMock).to have_requested(:delete, "https://cloud.tenable.com/was/v2/scans/#{scan_id}")
    end

    it 'returns nil for empty response' do
      result = resource.delete_scan(scan_id)

      expect(result).to be_nil
    end
  end

  describe '#search_scans' do
    let(:config_id) { 'cfg-abc-123' }
    let(:response_body) do
      {
        'items' => [{ 'scan_id' => 'scan-xyz-789', 'status' => 'completed' }],
        'pagination' => { 'total' => 1, 'offset' => 0, 'limit' => 50 }
      }
    end

    before do
      stub_request(:post, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/search")
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /was/v2/configs/{config_id}/scans/search' do
      resource.search_scans(config_id, filter: { status: 'completed' })

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/search")
    end

    it 'returns search results' do
      result = resource.search_scans(config_id, filter: { status: 'completed' })

      expect(result['items']).to be_an(Array)
      expect(result['items'].first['scan_id']).to eq('scan-xyz-789')
    end
  end

  describe '#search_vulnerabilities' do
    let(:response_body) do
      {
        'items' => [{ 'vuln_id' => 'v-001', 'name' => 'SQL Injection', 'severity' => 'high' }],
        'pagination' => { 'total' => 1, 'offset' => 0, 'limit' => 50 }
      }
    end

    before do
      stub_request(:post, 'https://cloud.tenable.com/was/v2/vulnerabilities/search')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /was/v2/vulnerabilities/search' do
      resource.search_vulnerabilities(filter: { severity: 'high' })

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/was/v2/vulnerabilities/search')
    end

    it 'returns vulnerability search results' do
      result = resource.search_vulnerabilities(filter: { severity: 'high' })

      expect(result['items'].first['name']).to eq('SQL Injection')
    end
  end

  describe '#vulnerability_details' do
    let(:vuln_id) { 'v-001' }
    let(:response_body) do
      { 'vuln_id' => vuln_id, 'name' => 'SQL Injection', 'severity' => 'high', 'description' => 'A SQL injection...' }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v2/vulnerabilities/#{vuln_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /was/v2/vulnerabilities/{vuln_id}' do
      resource.vulnerability_details(vuln_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/vulnerabilities/#{vuln_id}")
    end

    it 'returns vulnerability details' do
      result = resource.vulnerability_details(vuln_id)

      expect(result['vuln_id']).to eq(vuln_id)
      expect(result['name']).to eq('SQL Injection')
    end
  end

  describe '#export_scan' do
    let(:scan_id) { 'scan-xyz-789' }
    let(:response_body) { { 'scan_id' => scan_id, 'status' => 'exporting' } }

    before do
      stub_request(:put, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
        .with(body: JSON.generate({ 'format' => 'pdf' }), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a PUT request to /was/v2/scans/{scan_id}/report with format' do
      resource.export_scan(scan_id, format: 'pdf')

      expect(WebMock).to have_requested(:put, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
        .with(body: JSON.generate({ 'format' => 'pdf' }))
    end

    it 'returns the export initiation response' do
      result = resource.export_scan(scan_id, format: 'pdf')

      expect(result['status']).to eq('exporting')
    end

    it 'raises ArgumentError for unsupported format' do
      expect { resource.export_scan(scan_id, format: 'nessus') }
        .to raise_error(ArgumentError, /Unsupported format 'nessus'/)
    end
  end

  describe '#export_scan_status' do
    let(:scan_id) { 'scan-xyz-789' }

    context 'when report is ready' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
          .to_return(status: 200, body: 'report content', headers: { 'Content-Type' => 'application/octet-stream' })
      end

      it 'returns ready status when the report endpoint returns 200' do
        result = resource.export_scan_status(scan_id)

        expect(result['status']).to eq('ready')
      end
    end

    context 'when report is not ready' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
          .to_return(status: 404, body: '', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns loading status when the report endpoint returns 404' do
        result = resource.export_scan_status(scan_id)

        expect(result['status']).to eq('loading')
      end
    end
  end

  describe '#wait_for_scan_export' do
    let(:scan_id) { 'scan-xyz-789' }

    context 'when export becomes ready after polling' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
          .to_return(
            { status: 404, body: '', headers: { 'Content-Type' => 'application/json' } },
            { status: 200, body: 'report content', headers: { 'Content-Type' => 'application/octet-stream' } }
          )
      end

      it 'polls until status is ready' do
        result = resource.wait_for_scan_export(scan_id, timeout: 30, poll_interval: 0)

        expect(result['status']).to eq('ready')
        expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report").times(2)
      end
    end

    context 'when export times out' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
          .to_return(status: 404, body: '', headers: { 'Content-Type' => 'application/json' })
      end

      it 'raises TimeoutError' do
        expect { resource.wait_for_scan_export(scan_id, timeout: 0, poll_interval: 0) }
          .to raise_error(Tenable::TimeoutError, /timed out/)
      end
    end
  end

  describe '#export' do
    let(:scan_id) { 'scan-xyz-789' }
    let(:binary_content) { "\x50\x4B\x03\x04 fake pdf content" }

    before do
      stub_request(:put, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
        .with(body: JSON.generate({ 'format' => 'pdf' }), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate({ 'status' => 'exporting' }),
                   headers: { 'Content-Type' => 'application/json' })

      # First call for status check (returns ready), second call for download
      stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
        .to_return(
          { status: 200, body: 'ready', headers: { 'Content-Type' => 'application/octet-stream' } },
          { status: 200, body: binary_content, headers: { 'Content-Type' => 'application/octet-stream' } }
        )
    end

    it 'chains export_scan, wait, and download returning binary content' do
      result = resource.export(scan_id, format: 'pdf', timeout: 30, poll_interval: 0)

      expect(result).to eq(binary_content)
      expect(WebMock).to have_requested(:put, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report").once
      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report").times(2)
    end

    context 'with save_path' do
      let(:tmpfile) { Tempfile.new(['was_export', '.pdf']) }

      after { tmpfile.close! }

      it 'writes binary content to disk and returns the path' do
        result = resource.export(scan_id, format: 'pdf', save_path: tmpfile.path, timeout: 30, poll_interval: 0)

        expect(result).to eq(tmpfile.path)
        expect(File.binread(tmpfile.path)).to eq(binary_content)
      end
    end
  end

  describe '#download_scan_export' do
    let(:scan_id) { 'scan-xyz-789' }
    let(:binary_content) { "\x50\x4B\x03\x04 fake zip content" }

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
        .to_return(status: 200, body: binary_content, headers: { 'Content-Type' => 'application/octet-stream' })
    end

    it 'sends a GET request to the report endpoint' do
      resource.download_scan_export(scan_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/report")
    end

    it 'returns raw binary content' do
      result = resource.download_scan_export(scan_id)

      expect(result).to be_a(String)
      expect(result).to eq(binary_content)
    end
  end

  describe '#export_findings' do
    let(:export_uuid) { 'exp-abc-123' }

    before do
      stub_request(:post, 'https://cloud.tenable.com/was/v1/export/vulns')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: JSON.generate({ 'export_uuid' => export_uuid }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to /was/v1/export/vulns' do
      resource.export_findings(severity: 'high')

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/was/v1/export/vulns')
    end

    it 'returns the export UUID' do
      result = resource.export_findings(severity: 'high')

      expect(result['export_uuid']).to eq(export_uuid)
    end
  end

  describe '#export_findings_status' do
    let(:export_uuid) { 'exp-abc-123' }

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v1/export/vulns/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'FINISHED', 'chunks_available' => [0] }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to the status endpoint' do
      resource.export_findings_status(export_uuid)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v1/export/vulns/#{export_uuid}/status")
    end

    it 'returns status data' do
      result = resource.export_findings_status(export_uuid)

      expect(result['status']).to eq('FINISHED')
    end
  end

  describe '#export_findings_chunk' do
    let(:export_uuid) { 'exp-abc-123' }
    let(:chunk_data) do
      [{ 'vuln_id' => 'v-001', 'name' => 'SQL Injection' }]
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/was/v1/export/vulns/#{export_uuid}/chunks/0")
        .to_return(status: 200, body: JSON.generate(chunk_data), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to the chunk endpoint' do
      resource.export_findings_chunk(export_uuid, 0)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v1/export/vulns/#{export_uuid}/chunks/0")
    end

    it 'returns an array of finding records' do
      result = resource.export_findings_chunk(export_uuid, 0)

      expect(result).to be_an(Array)
      expect(result.first['vuln_id']).to eq('v-001')
    end
  end

  describe '#export_findings_cancel' do
    let(:export_uuid) { 'exp-abc-123' }

    before do
      stub_request(:post, "https://cloud.tenable.com/was/v1/export/vulns/#{export_uuid}/cancel")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'CANCELLED' }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to the cancel endpoint' do
      resource.export_findings_cancel(export_uuid)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/was/v1/export/vulns/#{export_uuid}/cancel")
    end

    it 'returns the cancellation response' do
      result = resource.export_findings_cancel(export_uuid)

      expect(result['status']).to eq('CANCELLED')
    end
  end
end
