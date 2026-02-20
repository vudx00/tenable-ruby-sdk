# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Models::WebAppScanConfig do
  subject(:config) { described_class.from_api(attributes) }

  context 'when initialized with all attributes' do
    let(:attributes) do
      {
        'config_id' => 'cfg-abc-123',
        'name' => 'Production App Config',
        'target' => 'https://example.com',
        'status' => 'active',
        'tracking_id' => 'trk-xyz-789'
      }
    end

    it 'returns the config_id as a String' do
      expect(config.config_id).to eq('cfg-abc-123')
    end

    it 'returns the name as a String' do
      expect(config.name).to eq('Production App Config')
    end

    it 'returns the target as a String' do
      expect(config.target).to eq('https://example.com')
    end

    it 'returns the status as a String' do
      expect(config.status).to eq('active')
    end

    it 'returns the tracking_id as a String' do
      expect(config.tracking_id).to eq('trk-xyz-789')
    end
  end

  context 'when initialized with missing attributes' do
    let(:attributes) do
      {
        'config_id' => 'cfg-minimal',
        'name' => 'Minimal Config',
        'target' => 'https://minimal.example.com',
        'status' => 'draft'
      }
    end

    it 'defaults tracking_id to nil' do
      expect(config.tracking_id).to be_nil
    end
  end
end
