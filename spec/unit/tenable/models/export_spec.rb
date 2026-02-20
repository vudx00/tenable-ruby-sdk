# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Models::Export do
  let(:full_hash) do
    {
      'uuid' => 'export-uuid-1234-5678-abcdef',
      'status' => 'FINISHED',
      'chunks_available' => [1, 2, 3, 4, 5],
      'chunks_failed' => [6],
      'chunks_cancelled' => []
    }
  end

  let(:minimal_hash) do
    {
      'uuid' => 'export-uuid-minimal',
      'status' => 'QUEUED'
    }
  end

  describe 'initialization from a hash' do
    subject(:export) { described_class.from_api(full_hash) }

    it 'sets uuid' do
      expect(export.uuid).to eq('export-uuid-1234-5678-abcdef')
    end

    it 'sets status' do
      expect(export.status).to eq('FINISHED')
    end

    it 'sets chunks_available as an Array' do
      expect(export.chunks_available).to eq([1, 2, 3, 4, 5])
      expect(export.chunks_available).to be_an(Array)
    end

    it 'sets chunks_failed as an Array' do
      expect(export.chunks_failed).to eq([6])
      expect(export.chunks_failed).to be_an(Array)
    end

    it 'sets chunks_cancelled as an Array' do
      expect(export.chunks_cancelled).to eq([])
      expect(export.chunks_cancelled).to be_an(Array)
    end
  end

  describe 'defaults for missing attributes' do
    subject(:export) { described_class.from_api(minimal_hash) }

    it 'defaults chunks_available to an empty Array' do
      expect(export.chunks_available).to eq([])
    end

    it 'defaults chunks_failed to an empty Array' do
      expect(export.chunks_failed).to eq([])
    end

    it 'defaults chunks_cancelled to an empty Array' do
      expect(export.chunks_cancelled).to eq([])
    end
  end

  describe 'status values' do
    %w[QUEUED PROCESSING FINISHED ERROR CANCELLED].each do |status_value|
      it "accepts #{status_value} as a valid status" do
        export = described_class.from_api('uuid' => 'test-uuid', 'status' => status_value)
        expect(export.status).to eq(status_value)
      end
    end
  end

  describe 'helper methods' do
    describe '#finished?' do
      it 'returns true when status is FINISHED' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'FINISHED')
        expect(export.finished?).to be true
      end

      it 'returns false when status is not FINISHED' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'PROCESSING')
        expect(export.finished?).to be false
      end
    end

    describe '#processing?' do
      it 'returns true when status is PROCESSING' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'PROCESSING')
        expect(export.processing?).to be true
      end

      it 'returns false when status is not PROCESSING' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'FINISHED')
        expect(export.processing?).to be false
      end
    end

    describe '#error?' do
      it 'returns true when status is ERROR' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'ERROR')
        expect(export.error?).to be true
      end

      it 'returns false when status is not ERROR' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'FINISHED')
        expect(export.error?).to be false
      end
    end

    describe '#queued?' do
      it 'returns true when status is QUEUED' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'QUEUED')
        expect(export.queued?).to be true
      end

      it 'returns false when status is not QUEUED' do
        export = described_class.from_api('uuid' => 'test', 'status' => 'FINISHED')
        expect(export.queued?).to be false
      end
    end
  end
end
