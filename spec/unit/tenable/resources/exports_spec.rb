# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Resources::Exports do
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

  let(:export_uuid) { 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' }

  describe '#export' do
    before do
      stub_request(:post, 'https://cloud.tenable.com/vulns/export')
        .with(
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate({ filters: { severity: ['critical'] } })
        )
        .to_return(
          status: 200,
          body: JSON.generate({ 'export_uuid' => export_uuid }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'initiates a vulnerability export and returns the export UUID' do
      result = resource.export(filters: { severity: ['critical'] })

      expect(result['export_uuid']).to eq(export_uuid)
    end

    it 'sends a POST request to the vulns/export endpoint' do
      resource.export(filters: { severity: ['critical'] })

      expect(
        a_request(:post, 'https://cloud.tenable.com/vulns/export')
          .with(body: JSON.generate({ filters: { severity: ['critical'] } }))
      ).to have_been_made.once
    end
  end

  describe '#status' do
    before do
      stub_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({
                                'status' => 'FINISHED',
                                'chunks_available' => [0, 1, 2]
                              }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns the export status' do
      result = resource.status(export_uuid)

      expect(result['status']).to eq('FINISHED')
    end

    it 'includes available chunk IDs' do
      result = resource.status(export_uuid)

      expect(result['chunks_available']).to eq([0, 1, 2])
    end

    it 'sends a GET request to the status endpoint' do
      resource.status(export_uuid)

      expect(
        a_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/status")
      ).to have_been_made.once
    end
  end

  describe '#cancel' do
    before do
      stub_request(:post, "https://cloud.tenable.com/vulns/export/#{export_uuid}/cancel")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'CANCELLED' }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to the cancel endpoint' do
      resource.cancel(export_uuid)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/vulns/export/#{export_uuid}/cancel")
    end

    it 'returns the cancellation response' do
      result = resource.cancel(export_uuid)

      expect(result['status']).to eq('CANCELLED')
    end
  end

  describe '#download_chunk' do
    let(:chunk_id) { 0 }
    let(:chunk_data) do
      [
        {
          'asset' => { 'uuid' => 'asset-001' },
          'plugin' => { 'id' => 19_506, 'name' => 'Nessus Scan Information' },
          'severity' => 'info'
        },
        {
          'asset' => { 'uuid' => 'asset-002' },
          'plugin' => { 'id' => 10_863, 'name' => 'SSL Certificate Information' },
          'severity' => 'medium'
        }
      ]
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/chunks/#{chunk_id}")
        .to_return(
          status: 200,
          body: JSON.generate(chunk_data),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'downloads vulnerability data for the given chunk' do
      result = resource.download_chunk(export_uuid, chunk_id)

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
    end

    it 'returns vulnerability objects with expected attributes' do
      result = resource.download_chunk(export_uuid, chunk_id)

      vuln = result.first
      expect(vuln['plugin']['id']).to eq(19_506)
      expect(vuln['severity']).to eq('info')
    end

    it 'sends a GET request to the chunk download endpoint' do
      resource.download_chunk(export_uuid, chunk_id)

      expect(
        a_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/chunks/#{chunk_id}")
      ).to have_been_made.once
    end
  end

  describe '#each' do
    let(:chunk_0_data) do
      [
        {
          'asset' => { 'uuid' => 'asset-001' },
          'plugin' => { 'id' => 19_506, 'name' => 'Nessus Scan Information' },
          'severity' => 'info'
        }
      ]
    end

    let(:chunk_1_data) do
      [
        {
          'asset' => { 'uuid' => 'asset-002' },
          'plugin' => { 'id' => 10_863, 'name' => 'SSL Certificate Information' },
          'severity' => 'medium'
        },
        {
          'asset' => { 'uuid' => 'asset-003' },
          'plugin' => { 'id' => 12_345, 'name' => 'Critical Vulnerability' },
          'severity' => 'critical'
        }
      ]
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({
                                'status' => 'FINISHED',
                                'chunks_available' => [0, 1]
                              }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/chunks/0")
        .to_return(
          status: 200,
          body: JSON.generate(chunk_0_data),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/chunks/1")
        .to_return(
          status: 200,
          body: JSON.generate(chunk_1_data),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'yields vulnerability objects from all chunks' do
      vulns = []
      resource.each(export_uuid) { |v| vulns << v }

      expect(vulns.length).to eq(3)
    end

    it 'yields vulnerabilities in chunk order' do
      plugin_ids = []
      resource.each(export_uuid) { |v| plugin_ids << v['plugin']['id'] }

      expect(plugin_ids).to eq([19_506, 10_863, 12_345])
    end

    it 'fetches all available chunks' do
      resource.each(export_uuid) { |_v| } # rubocop:disable Lint/EmptyBlock

      expect(
        a_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/chunks/0")
      ).to have_been_made.once

      expect(
        a_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/chunks/1")
      ).to have_been_made.once
    end
  end

  describe 'timeout handling' do
    before do
      stub_request(:get, "https://cloud.tenable.com/vulns/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({
                                'status' => 'PROCESSING',
                                'chunks_available' => []
                              }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'raises a TimeoutError when the export does not complete in time' do
      expect { resource.wait_for_completion(export_uuid, timeout: 0) }
        .to raise_error(Tenable::TimeoutError, /#{export_uuid}/)
    end

    it 'includes the export UUID in the error message' do
      error = nil
      begin
        resource.wait_for_completion(export_uuid, timeout: 0)
      rescue Tenable::TimeoutError => e
        error = e
      end

      expect(error.message).to include(export_uuid)
    end
  end
end
