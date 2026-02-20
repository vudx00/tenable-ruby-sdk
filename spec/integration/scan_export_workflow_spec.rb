# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Scan export workflow', :integration do
  let(:access_key) { 'ak' }
  let(:secret_key) { 'sk' }
  let(:base_url) { 'https://cloud.tenable.com' }
  let(:scan_id) { 42 }
  let(:file_id) { 12_345 }
  let(:api_keys_header) { "accessKey=#{access_key};secretKey=#{secret_key};" }
  let(:binary_content) { "\x25PDF-1.4 fake report binary data" }

  let(:client) { Tenable::Client.new(access_key: access_key, secret_key: secret_key) }

  describe 'request export -> poll status -> download binary' do
    before do
      stub_request(:post, "#{base_url}/scans/#{scan_id}/export")
        .with(
          headers: { 'X-ApiKeys' => api_keys_header },
          body: { 'format' => 'pdf' }.to_json
        )
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: { 'file' => file_id }.to_json
        )

      stub_request(:get, "#{base_url}/scans/#{scan_id}/export/#{file_id}/status")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'loading' }.to_json },
          { status: 200, headers: { 'Content-Type' => 'application/json' },
            body: { 'status' => 'ready' }.to_json }
        )

      stub_request(:get, "#{base_url}/scans/#{scan_id}/export/#{file_id}/download")
        .with(headers: { 'X-ApiKeys' => api_keys_header })
        .to_return(
          status: 200,
          headers: { 'Content-Type' => 'application/octet-stream' },
          body: binary_content
        )
    end

    it 'exports a scan report using the convenience method' do
      allow(client.scans).to receive(:sleep)

      result = client.scans.export(scan_id, format: 'pdf', timeout: 60, poll_interval: 1)

      expect(result).to be_a(String)
      expect(result).to eq(binary_content)

      expect(WebMock).to have_requested(:post, "#{base_url}/scans/#{scan_id}/export")
        .with(body: hash_including('format' => 'pdf'))
      expect(WebMock).to have_requested(:get, "#{base_url}/scans/#{scan_id}/export/#{file_id}/status")
        .times(2)
      expect(WebMock).to have_requested(:get, "#{base_url}/scans/#{scan_id}/export/#{file_id}/download")
        .once
    end

    it 'saves to a file when save_path is provided' do
      require 'tempfile'
      tmpfile = Tempfile.new(['scan_report', '.pdf'])
      path = tmpfile.path
      tmpfile.close

      allow(client.scans).to receive(:sleep)

      result = client.scans.export(scan_id, format: 'pdf', save_path: path, timeout: 60, poll_interval: 1)

      expect(result).to eq(path)
      expect(File.binread(path)).to eq(binary_content)
    ensure
      tmpfile&.unlink
    end
  end

  describe 'export with unsupported format' do
    it 'raises ArgumentError without making any API calls' do
      expect { client.scans.export_request(scan_id, format: 'html') }
        .to raise_error(ArgumentError, /Unsupported format 'html'/)
    end
  end
end
