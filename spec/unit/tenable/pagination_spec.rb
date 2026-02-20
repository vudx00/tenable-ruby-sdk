# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Pagination do
  it 'includes Enumerable' do
    expect(described_class.ancestors).to include(Enumerable)
  end

  describe '#each' do
    it 'returns an Enumerator when no block is given' do
      paginator = described_class.new(limit: 10) do |_offset, _limit|
        { total: 0, items: [] }
      end

      expect(paginator.each).to be_a(Enumerator)
    end

    it 'yields items when given a block' do
      paginator = described_class.new(limit: 10) do |_offset, _limit|
        { total: 3, items: %w[a b c] }
      end

      collected = paginator.map { |item| item }

      expect(collected).to eq(%w[a b c])
    end

    it 'auto-fetches next page when offset < total' do
      call_count = 0

      paginator = described_class.new(limit: 2) do |offset, _limit|
        call_count += 1
        case offset
        when 0
          { total: 5, items: %w[a b] }
        when 2
          { total: 5, items: %w[c d] }
        when 4
          { total: 5, items: %w[e] }
        else
          { total: 5, items: [] }
        end
      end

      results = paginator.each.to_a

      expect(results).to eq(%w[a b c d e])
      expect(call_count).to eq(3)
    end

    it 'stops when offset >= total' do
      call_count = 0

      paginator = described_class.new(limit: 3) do |_offset, _limit|
        call_count += 1
        { total: 3, items: %w[x y z] }
      end

      results = paginator.each.to_a

      expect(results).to eq(%w[x y z])
      expect(call_count).to eq(1)
    end

    it 'handles empty page gracefully' do
      paginator = described_class.new(limit: 10) do |_offset, _limit|
        { total: 0, items: [] }
      end

      results = paginator.each.to_a

      expect(results).to be_empty
    end

    it 'supports lazy enumeration' do
      paginator = described_class.new(limit: 10) do |_offset, _limit|
        { total: 3, items: %w[a b c] }
      end

      expect(paginator.lazy).to be_a(Enumerator::Lazy)
    end

    it 'caps the page size at a maximum of 200' do
      requested_limit = nil

      paginator = described_class.new(limit: 500) do |_offset, limit|
        requested_limit = limit
        { total: 0, items: [] }
      end

      paginator.each.to_a

      expect(requested_limit).to eq(200)
    end
  end
end
