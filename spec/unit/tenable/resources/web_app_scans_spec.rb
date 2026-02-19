# frozen_string_literal: true

require 'spec_helper'

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

  describe '#findings' do
    let(:config_id) { 'cfg-abc-123' }
    let(:response_body) do
      {
        'findings' => [
          {
            'finding_id' => 'f-001',
            'name' => 'SQL Injection',
            'severity' => 'high',
            'url' => 'https://app.example.com/login'
          },
          {
            'finding_id' => 'f-002',
            'name' => 'Cross-Site Scripting',
            'severity' => 'medium',
            'url' => 'https://app.example.com/search'
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
      stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/findings")
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to /was/v2/configs/{config_id}/findings' do
      resource.findings(config_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/findings")
    end

    it 'returns a parsed hash with findings array and pagination' do
      result = resource.findings(config_id)

      expect(result).to be_a(Hash)
      expect(result['findings']).to be_an(Array)
      expect(result['findings'].length).to eq(2)
      expect(result['pagination']['total']).to eq(15)
    end

    it 'returns finding objects with expected attributes' do
      result = resource.findings(config_id)

      finding = result['findings'].first
      expect(finding['finding_id']).to eq('f-001')
      expect(finding['name']).to eq('SQL Injection')
      expect(finding['severity']).to eq('high')
    end

    context 'with pagination parameters' do
      before do
        stub_request(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/findings")
          .with(query: { 'offset' => '2', 'limit' => '5' })
          .to_return(
            status: 200,
            body: JSON.generate({
                                  'findings' => [
                                    { 'finding_id' => 'f-003', 'name' => 'Open Redirect', 'severity' => 'low' }
                                  ],
                                  'pagination' => { 'total' => 15, 'offset' => 2, 'limit' => 5 }
                                }),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'passes pagination parameters as query params' do
        result = resource.findings(config_id, offset: 2, limit: 5)

        expect(result['findings'].length).to eq(1)
        expect(result['pagination']['offset']).to eq(2)
        expect(result['pagination']['limit']).to eq(5)
      end
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
        result = resource.wait_until_complete(config_id, scan_id)

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
        result = resource.wait_until_complete(config_id, scan_id)

        expect(result['status']).to eq('failed')
        expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/configs/#{config_id}/scans/#{scan_id}").times(2)
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
      stub_request(:patch, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/status")
        .with(body: JSON.generate({ 'status' => 'stopped' }), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a PATCH request with stopped status' do
      resource.stop_scan(scan_id)

      expect(WebMock).to have_requested(:patch, "https://cloud.tenable.com/was/v2/scans/#{scan_id}/status")
        .with(body: JSON.generate({ 'status' => 'stopped' }))
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
    let(:response_body) do
      {
        'items' => [{ 'scan_id' => 'scan-xyz-789', 'status' => 'completed' }],
        'pagination' => { 'total' => 1, 'offset' => 0, 'limit' => 50 }
      }
    end

    before do
      stub_request(:post, 'https://cloud.tenable.com/was/v2/scans/search')
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /was/v2/scans/search' do
      resource.search_scans(filter: { status: 'completed' })

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/was/v2/scans/search')
    end

    it 'returns search results' do
      result = resource.search_scans(filter: { status: 'completed' })

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
      stub_request(:get, "https://cloud.tenable.com/was/v2/vulns/#{vuln_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /was/v2/vulns/{vuln_id}' do
      resource.vulnerability_details(vuln_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/was/v2/vulns/#{vuln_id}")
    end

    it 'returns vulnerability details' do
      result = resource.vulnerability_details(vuln_id)

      expect(result['vuln_id']).to eq(vuln_id)
      expect(result['name']).to eq('SQL Injection')
    end
  end
end
