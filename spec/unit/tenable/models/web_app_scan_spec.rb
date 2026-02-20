# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Models::WebAppScan do
  subject(:web_app_scan) { described_class.from_api(attributes) }

  context 'when initialized with all attributes' do
    let(:attributes) do
      {
        'scan_id' => 'scan-abc-123',
        'config_id' => 'cfg-abc-123',
        'status' => 'completed',
        'started_at' => '2026-01-15T10:00:00Z',
        'completed_at' => '2026-01-15T11:30:00Z',
        'findings_count' => 12
      }
    end

    it 'returns the scan_id as a String' do
      expect(web_app_scan.scan_id).to eq('scan-abc-123')
    end

    it 'returns the config_id as a String' do
      expect(web_app_scan.config_id).to eq('cfg-abc-123')
    end

    it 'returns the status as a String' do
      expect(web_app_scan.status).to eq('completed')
    end

    it 'returns the started_at as a String' do
      expect(web_app_scan.started_at).to eq('2026-01-15T10:00:00Z')
    end

    it 'returns the completed_at as a String' do
      expect(web_app_scan.completed_at).to eq('2026-01-15T11:30:00Z')
    end

    it 'returns the findings_count as an Integer' do
      expect(web_app_scan.findings_count).to eq(12)
    end
  end

  context 'when initialized with missing attributes' do
    let(:attributes) do
      {
        'scan_id' => 'scan-minimal',
        'config_id' => 'cfg-minimal',
        'status' => 'pending'
      }
    end

    it 'defaults started_at to nil' do
      expect(web_app_scan.started_at).to be_nil
    end

    it 'defaults completed_at to nil' do
      expect(web_app_scan.completed_at).to be_nil
    end

    it 'defaults findings_count to 0' do
      expect(web_app_scan.findings_count).to eq(0)
    end
  end
end
