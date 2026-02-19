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
end
