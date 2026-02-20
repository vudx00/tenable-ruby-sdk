# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Resources::AssetExports do
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
      stub_request(:post, 'https://cloud.tenable.com/assets/export')
        .with(
          headers: { 'Content-Type' => 'application/json' },
          body: JSON.generate({ chunk_size: 100 })
        )
        .to_return(
          status: 200,
          body: JSON.generate({ 'export_uuid' => export_uuid }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to /assets/export' do
      resource.export(chunk_size: 100)

      expect(WebMock).to have_requested(:post, 'https://cloud.tenable.com/assets/export')
        .with(body: JSON.generate({ chunk_size: 100 }))
    end

    it 'returns the export UUID' do
      result = resource.export(chunk_size: 100)

      expect(result['export_uuid']).to eq(export_uuid)
    end
  end

  describe '#status' do
    before do
      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'FINISHED', 'chunks_available' => [0, 1] }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to the status endpoint' do
      resource.status(export_uuid)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/status")
    end

    it 'returns status data' do
      result = resource.status(export_uuid)

      expect(result['status']).to eq('FINISHED')
      expect(result['chunks_available']).to eq([0, 1])
    end
  end

  describe '#download_chunk' do
    let(:chunk_data) do
      [
        { 'id' => 'asset-001', 'fqdn' => ['host1.example.com'] },
        { 'id' => 'asset-002', 'fqdn' => ['host2.example.com'] }
      ]
    end

    before do
      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/chunks/0")
        .to_return(
          status: 200,
          body: JSON.generate(chunk_data),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a GET request to the chunk endpoint' do
      resource.download_chunk(export_uuid, 0)

      expect(WebMock).to have_requested(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/chunks/0")
    end

    it 'returns an array of asset records' do
      result = resource.download_chunk(export_uuid, 0)

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result.first['id']).to eq('asset-001')
    end
  end

  describe '#cancel' do
    before do
      stub_request(:post, "https://cloud.tenable.com/assets/export/#{export_uuid}/cancel")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'CANCELLED' }),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'sends a POST request to the cancel endpoint' do
      resource.cancel(export_uuid)

      expect(WebMock).to have_requested(:post, "https://cloud.tenable.com/assets/export/#{export_uuid}/cancel")
    end

    it 'returns the cancellation response' do
      result = resource.cancel(export_uuid)

      expect(result['status']).to eq('CANCELLED')
    end
  end

  describe '#each' do
    let(:first_chunk) { [{ 'id' => 'asset-001' }] }
    let(:second_chunk) { [{ 'id' => 'asset-002' }, { 'id' => 'asset-003' }] }

    before do
      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'FINISHED', 'chunks_available' => [0, 1] }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/chunks/0")
        .to_return(status: 200, body: JSON.generate(first_chunk), headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/chunks/1")
        .to_return(status: 200, body: JSON.generate(second_chunk), headers: { 'Content-Type' => 'application/json' })
    end

    it 'yields all asset records from all chunks' do
      assets = []
      resource.each(export_uuid) { |a| assets << a }

      expect(assets.length).to eq(3)
    end

    it 'yields assets in chunk order' do
      ids = []
      resource.each(export_uuid) { |a| ids << a['id'] }

      expect(ids).to eq(%w[asset-001 asset-002 asset-003])
    end
  end

  describe '#wait_for_completion' do
    it 'raises TimeoutError when export does not complete in time' do
      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'PROCESSING', 'chunks_available' => [] }),
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { resource.wait_for_completion(export_uuid, timeout: 0) }
        .to raise_error(Tenable::TimeoutError, /#{export_uuid}/)
    end

    it 'raises ApiError when export status is ERROR' do
      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'ERROR' }),
          headers: { 'Content-Type' => 'application/json' }
        )

      expect { resource.wait_for_completion(export_uuid, timeout: 60) }
        .to raise_error(Tenable::ApiError, /#{export_uuid}/)
    end
  end

  describe '#each without a block' do
    before do
      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/status")
        .to_return(
          status: 200,
          body: JSON.generate({ 'status' => 'FINISHED', 'chunks_available' => [0] }),
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://cloud.tenable.com/assets/export/#{export_uuid}/chunks/0")
        .to_return(
          status: 200,
          body: JSON.generate([{ 'id' => 'asset-001' }]),
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'returns an Enumerator when no block is given' do
      result = resource.each(export_uuid)

      expect(result).to be_an(Enumerator)
    end

    it 'enumerates records via the returned Enumerator' do
      records = resource.each(export_uuid).to_a

      expect(records.length).to eq(1)
      expect(records.first['id']).to eq('asset-001')
    end
  end

  describe 'path validation' do
    it 'rejects traversal attempts in export_uuid' do
      expect { resource.status('../evil') }
        .to raise_error(ArgumentError, /unsafe characters/)
    end
  end
end
