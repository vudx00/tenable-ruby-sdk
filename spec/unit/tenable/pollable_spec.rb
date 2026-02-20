# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tenable::Pollable do
  let(:pollable) do
    Class.new { include Tenable::Pollable }.new
  end

  describe '#poll_until' do
    it 'returns the block result when truthy' do
      result = pollable.poll_until(timeout: 5, poll_interval: 0.1, label: 'test') { 'done' }
      expect(result).to eq('done')
    end

    it 'raises TimeoutError when timeout expires' do
      expect do
        pollable.poll_until(timeout: 0, poll_interval: 0.1, label: 'test op') { nil }
      end.to raise_error(Tenable::TimeoutError, /test op/)
    end

    it 'includes the label in the error message' do
      expect do
        pollable.poll_until(timeout: 0, poll_interval: 0.1, label: 'my-export') { nil }
      end.to raise_error(Tenable::TimeoutError, /my-export/)
    end

    it 'polls multiple times before success' do
      call_count = 0
      pollable.poll_until(timeout: 5, poll_interval: 0.01, label: 'test') do
        call_count += 1
        call_count >= 3 ? 'done' : nil
      end
      expect(call_count).to eq(3)
    end
  end
end
