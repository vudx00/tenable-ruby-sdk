# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Models::Finding do
  subject(:finding) { described_class.from_api(attributes) }

  context 'when initialized with all attributes' do
    let(:attributes) do
      {
        'finding_id' => 'fnd-abc-123',
        'severity' => 'high',
        'url' => 'https://example.com/vulnerable-path',
        'name' => 'SQL Injection',
        'description' => 'User input is not properly sanitized before being used in a SQL query.',
        'remediation' => 'Use parameterized queries or prepared statements.',
        'plugin_id' => 98_765
      }
    end

    it 'returns the finding_id as a String' do
      expect(finding.finding_id).to eq('fnd-abc-123')
    end

    it 'returns the severity as a String' do
      expect(finding.severity).to eq('high')
    end

    it 'returns the url as a String' do
      expect(finding.url).to eq('https://example.com/vulnerable-path')
    end

    it 'returns the name as a String' do
      expect(finding.name).to eq('SQL Injection')
    end

    it 'returns the description as a String' do
      expect(finding.description).to eq('User input is not properly sanitized before being used in a SQL query.')
    end

    it 'returns the remediation as a String' do
      expect(finding.remediation).to eq('Use parameterized queries or prepared statements.')
    end

    it 'returns the plugin_id as an Integer' do
      expect(finding.plugin_id).to eq(98_765)
    end
  end

  context 'when initialized with missing attributes' do
    let(:attributes) do
      {
        'finding_id' => 'fnd-minimal',
        'severity' => 'low',
        'url' => 'https://example.com/path',
        'name' => 'Information Disclosure',
        'description' => 'Server version is exposed in response headers.',
        'plugin_id' => 11_111
      }
    end

    it 'defaults remediation to nil' do
      expect(finding.remediation).to be_nil
    end
  end
end
