# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Models::Scan do
  subject(:scan) { described_class.new(attributes) }

  context 'when initialized with all attributes' do
    let(:attributes) do
      {
        'id' => 42,
        'uuid' => 'abc-123-def-456',
        'name' => 'Weekly Network Scan',
        'status' => 'completed',
        'folder_id' => 7,
        'type' => 'remote',
        'creation_date' => 1_700_000_000,
        'last_modification_date' => 1_700_100_000
      }
    end

    it 'returns the id as an Integer' do
      expect(scan.id).to eq(42)
    end

    it 'returns the uuid as a String' do
      expect(scan.uuid).to eq('abc-123-def-456')
    end

    it 'returns the name as a String' do
      expect(scan.name).to eq('Weekly Network Scan')
    end

    it 'returns the status as a String' do
      expect(scan.status).to eq('completed')
    end

    it 'returns the folder_id as an Integer' do
      expect(scan.folder_id).to eq(7)
    end

    it 'returns the type as a String' do
      expect(scan.type).to eq('remote')
    end

    it 'returns the creation_date as an Integer' do
      expect(scan.creation_date).to eq(1_700_000_000)
    end

    it 'returns the last_modification_date as an Integer' do
      expect(scan.last_modification_date).to eq(1_700_100_000)
    end
  end

  context 'when initialized with missing attributes' do
    let(:attributes) do
      {
        'id' => 1,
        'uuid' => 'minimal-uuid',
        'name' => 'Minimal Scan',
        'status' => 'pending',
        'folder_id' => 3,
        'type' => 'local'
      }
    end

    it 'defaults creation_date to nil' do
      expect(scan.creation_date).to be_nil
    end

    it 'defaults last_modification_date to nil' do
      expect(scan.last_modification_date).to be_nil
    end
  end
end
