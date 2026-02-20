# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Resources::Scans do
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
    let(:response_body) do
      {
        'scans' => [
          {
            'id' => 1,
            'name' => 'Weekly Network Scan',
            'status' => 'completed',
            'folder_id' => 3
          },
          {
            'id' => 2,
            'name' => 'Daily Web App Scan',
            'status' => 'running',
            'folder_id' => 3
          }
        ]
      }
    end

    before do
      stub_request(:get, 'https://cloud.tenable.com/scans')
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to /scans' do
      resource.list

      expect(WebMock).to have_requested(:get, 'https://cloud.tenable.com/scans')
    end

    it 'returns a parsed hash with a scans array' do
      result = resource.list

      expect(result).to be_a(Hash)
      expect(result).to have_key('scans')
      expect(result['scans']).to be_an(Array)
      expect(result['scans'].length).to eq(2)
    end

    it 'returns scan objects with expected attributes' do
      result = resource.list

      scan = result['scans'].first
      expect(scan['id']).to eq(1)
      expect(scan['name']).to eq('Weekly Network Scan')
      expect(scan['status']).to eq('completed')
    end
  end

  describe '#create' do
    let(:params) do
      {
        'uuid' => 'template-uuid-1234',
        'settings' => {
          'name' => 'New Scan',
          'text_targets' => '192.168.1.0/24',
          'launch' => 'ON_DEMAND'
        }
      }
    end

    let(:response_body) do
      {
        'scan' => {
          'id' => 42,
          'name' => 'New Scan',
          'status' => 'empty',
          'uuid' => 'template-uuid-1234'
        }
      }
    end

    before do
      stub_request(:post, 'https://cloud.tenable.com/scans')
        .with(
          body: JSON.generate(params),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to /scans with the provided body' do
      resource.create(params)

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/scans')
        .with(body: JSON.generate(params))
    end

    it 'returns a parsed hash with a scan key' do
      result = resource.create(params)

      expect(result).to be_a(Hash)
      expect(result).to have_key('scan')
      expect(result['scan']['id']).to eq(42)
      expect(result['scan']['name']).to eq('New Scan')
    end
  end

  describe '#launch' do
    let(:scan_id) { 42 }
    let(:response_body) do
      { 'scan_uuid' => 'abc-def-123-456' }
    end

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/launch")
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to /scans/{id}/launch' do
      resource.launch(scan_id)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/scans/#{scan_id}/launch")
    end

    it 'returns a parsed hash with scan_uuid' do
      result = resource.launch(scan_id)

      expect(result).to be_a(Hash)
      expect(result['scan_uuid']).to eq('abc-def-123-456')
    end
  end

  describe '#status' do
    let(:scan_id) { 42 }
    let(:response_body) do
      { 'status' => 'running' }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/latest-status")
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to /scans/{id}/latest-status' do
      resource.status(scan_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}/latest-status")
    end

    it 'returns a parsed hash with status' do
      result = resource.status(scan_id)

      expect(result).to be_a(Hash)
      expect(result['status']).to eq('running')
    end
  end

  describe '#export_request' do
    let(:scan_id) { 42 }
    let(:response_body) { { 'file' => 12_345 } }

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/export")
        .with(headers: { 'Content-Type' => 'application/json' })
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request with format in the body' do
      resource.export_request(scan_id, format: 'pdf', chapters: 'vuln_hosts_summary')

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/scans/#{scan_id}/export")
        .with(body: hash_including('format' => 'pdf', 'chapters' => 'vuln_hosts_summary'))
    end

    it 'returns a hash with the file ID' do
      result = resource.export_request(scan_id, format: 'pdf', chapters: 'vuln_hosts_summary')

      expect(result).to be_a(Hash)
      expect(result['file']).to eq(12_345)
    end

    it 'raises ArgumentError for unsupported formats' do
      expect { resource.export_request(scan_id, format: 'xml') }
        .to raise_error(ArgumentError, /Unsupported format 'xml'/)
    end
  end

  describe '#export_status' do
    let(:scan_id) { 42 }
    let(:file_id) { 12_345 }
    let(:response_body) { { 'status' => 'ready' } }

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/status")
        .to_return(
          status: 200,
          body: JSON.generate(response_body),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to the export status endpoint' do
      resource.export_status(scan_id, file_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/status")
    end

    it 'returns a hash with status' do
      result = resource.export_status(scan_id, file_id)

      expect(result).to be_a(Hash)
      expect(result['status']).to eq('ready')
    end
  end

  describe '#export_download' do
    let(:scan_id) { 42 }
    let(:file_id) { 12_345 }
    let(:binary_content) { "\x25PDF-1.4 fake binary content" }

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/download")
        .to_return(
          status: 200,
          body: binary_content,
          headers: { 'Content-Type' => 'application/octet-stream' }
        )
    end

    it 'sends a GET request to the download endpoint' do
      resource.export_download(scan_id, file_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/download")
    end

    it 'returns raw binary content without JSON parsing' do
      result = resource.export_download(scan_id, file_id)

      expect(result).to be_a(String)
      expect(result).to eq(binary_content)
    end
  end

  describe '#wait_for_export' do
    let(:scan_id) { 42 }
    let(:file_id) { 12_345 }

    it 'polls until status is ready' do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/status")
        .to_return(
          { status: 200, body: JSON.generate('status' => 'loading'),
            headers: { 'Content-Type' => 'application/json' } },
          { status: 200, body: JSON.generate('status' => 'loading'),
            headers: { 'Content-Type' => 'application/json' } },
          { status: 200, body: JSON.generate('status' => 'ready'), headers: { 'Content-Type' => 'application/json' } }
        )

      allow(resource).to receive(:sleep)

      result = resource.wait_for_export(scan_id, file_id, timeout: 60, poll_interval: 1)

      expect(result['status']).to eq('ready')
    end

    it 'raises TimeoutError when export does not become ready' do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/status")
        .to_return(
          status: 200,
          body: JSON.generate('status' => 'loading'),
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { resource.wait_for_export(scan_id, file_id, timeout: 0, poll_interval: 0) }
        .to raise_error(Tenable::TimeoutError, /timed out/)
    end
  end

  describe '#export' do
    let(:scan_id) { 42 }
    let(:file_id) { 12_345 }
    let(:binary_content) { "\x25PDF-1.4 fake pdf content" }

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/export")
        .with(
          body: JSON.generate(format: 'pdf'),
          headers: { 'Content-Type' => 'application/json' }
        )
        .to_return(
          status: 200,
          body: JSON.generate('file' => file_id),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/status")
        .to_return(
          status: 200,
          body: JSON.generate('status' => 'ready'),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/export/#{file_id}/download")
        .to_return(
          status: 200,
          body: binary_content,
          headers: { 'Content-Type' => 'application/octet-stream' }
        )

      allow(resource).to receive(:sleep)
    end

    it 'chains request, wait, and download to return binary content' do
      result = resource.export(scan_id, format: 'pdf', timeout: 60, poll_interval: 0)

      expect(result).to eq(binary_content)
    end

    it 'writes to disk and returns the path when save_path is given' do
      require 'tempfile'
      tmpfile = Tempfile.new(['scan_export', '.pdf'])
      path = tmpfile.path
      tmpfile.close

      result = resource.export(scan_id, format: 'pdf', save_path: path, timeout: 60, poll_interval: 0)

      expect(result).to eq(path)
      expect(File.binread(path)).to eq(binary_content)
    ensure
      tmpfile&.unlink
    end
  end

  describe '#details' do
    let(:scan_id) { 42 }
    let(:response_body) do
      { 'info' => { 'name' => 'My Scan', 'status' => 'completed' }, 'hosts' => [] }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /scans/{id}' do
      resource.details(scan_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}")
    end

    it 'returns parsed scan details' do
      result = resource.details(scan_id)

      expect(result['info']['name']).to eq('My Scan')
    end
  end

  describe '#update' do
    let(:scan_id) { 42 }
    let(:params) { { 'settings' => { 'name' => 'Updated Scan' } } }
    let(:response_body) { { 'id' => scan_id, 'name' => 'Updated Scan' } }

    before do
      stub_request(:put, "https://cloud.tenable.com/scans/#{scan_id}")
        .with(body: JSON.generate(params), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a PUT request to /scans/{id}' do
      resource.update(scan_id, params)

      expect(WebMock).to have_requested(:put, "https://cloud.tenable.com/scans/#{scan_id}")
        .with(body: JSON.generate(params))
    end

    it 'returns the updated scan data' do
      result = resource.update(scan_id, params)

      expect(result['name']).to eq('Updated Scan')
    end
  end

  describe '#destroy' do
    let(:scan_id) { 42 }

    before do
      stub_request(:delete, "https://cloud.tenable.com/scans/#{scan_id}")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a DELETE request to /scans/{id}' do
      resource.destroy(scan_id)

      expect(WebMock).to have_requested(:delete, "https://cloud.tenable.com/scans/#{scan_id}")
    end

    it 'returns nil for empty response' do
      result = resource.destroy(scan_id)

      expect(result).to be_nil
    end
  end

  describe '#pause' do
    let(:scan_id) { 42 }

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/pause")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /scans/{id}/pause' do
      resource.pause(scan_id)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/scans/#{scan_id}/pause")
    end
  end

  describe '#resume' do
    let(:scan_id) { 42 }

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/resume")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /scans/{id}/resume' do
      resource.resume(scan_id)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/scans/#{scan_id}/resume")
    end
  end

  describe '#stop' do
    let(:scan_id) { 42 }

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/stop")
        .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /scans/{id}/stop' do
      resource.stop(scan_id)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/scans/#{scan_id}/stop")
    end
  end

  describe '#copy' do
    let(:scan_id) { 42 }
    let(:response_body) { { 'id' => 99, 'name' => 'Copy of My Scan' } }

    before do
      stub_request(:post, "https://cloud.tenable.com/scans/#{scan_id}/copy")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a POST request to /scans/{id}/copy' do
      resource.copy(scan_id)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/scans/#{scan_id}/copy")
    end

    it 'returns the copied scan data' do
      result = resource.copy(scan_id)

      expect(result['id']).to eq(99)
    end
  end

  describe '#schedule' do
    let(:scan_id) { 42 }
    let(:params) { { 'enabled' => true, 'rules' => 'FREQ=DAILY' } }
    let(:response_body) { { 'enabled' => true, 'rules' => 'FREQ=DAILY' } }

    before do
      stub_request(:put, "https://cloud.tenable.com/scans/#{scan_id}/schedule")
        .with(body: JSON.generate(params), headers: { 'Content-Type' => 'application/json' })
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a PUT request to /scans/{id}/schedule' do
      resource.schedule(scan_id, params)

      expect(WebMock).to have_requested(:put, "https://cloud.tenable.com/scans/#{scan_id}/schedule")
        .with(body: JSON.generate(params))
    end

    it 'returns the schedule data' do
      result = resource.schedule(scan_id, params)

      expect(result['enabled']).to be true
    end
  end

  describe '#history' do
    let(:scan_id) { 42 }
    let(:response_body) do
      {
        'info' => { 'name' => 'My Scan', 'status' => 'completed' },
        'history' => [{ 'history_id' => 1, 'status' => 'completed' }]
      }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'fetches history from the scan details endpoint' do
      resource.history(scan_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}")
    end

    it 'returns the history array' do
      result = resource.history(scan_id)

      expect(result).to be_an(Array)
      expect(result.first['history_id']).to eq(1)
    end

    context 'when details response has no history key' do
      let(:response_body) { { 'info' => { 'name' => 'My Scan' } } }

      it 'returns an empty array' do
        result = resource.history(scan_id)

        expect(result).to eq([])
      end
    end
  end

  describe '#host_details' do
    let(:scan_id) { 42 }
    let(:host_id) { 5 }
    let(:response_body) do
      { 'info' => { 'host-ip' => '10.0.0.1', 'operating-system' => 'Linux' }, 'vulnerabilities' => [] }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/hosts/#{host_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /scans/{scan_id}/hosts/{host_id}' do
      resource.host_details(scan_id, host_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}/hosts/#{host_id}")
    end

    it 'returns host details' do
      result = resource.host_details(scan_id, host_id)

      expect(result['info']['host-ip']).to eq('10.0.0.1')
    end
  end

  describe '#plugin_output' do
    let(:scan_id) { 42 }
    let(:host_id) { 5 }
    let(:plugin_id) { 19_506 }
    let(:response_body) do
      { 'output' => [{ 'plugin_output' => 'Nessus scan info...', 'ports' => { '0' => [] } }] }
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/scans/#{scan_id}/hosts/#{host_id}/plugins/#{plugin_id}")
        .to_return(status: 200, body: JSON.generate(response_body), headers: { 'Content-Type' => 'application/json' })
    end

    it 'sends a GET request to /scans/{scan_id}/hosts/{host_id}/plugins/{plugin_id}' do
      resource.plugin_output(scan_id, host_id, plugin_id)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/scans/#{scan_id}/hosts/#{host_id}/plugins/#{plugin_id}")
    end

    it 'returns plugin output data' do
      result = resource.plugin_output(scan_id, host_id, plugin_id)

      expect(result['output']).to be_an(Array)
      expect(result['output'].first['plugin_output']).to include('Nessus')
    end
  end
end
