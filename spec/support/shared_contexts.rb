# frozen_string_literal: true

RSpec.shared_context 'with authenticated client' do
  let(:access_key) { 'test-access-key' }
  let(:secret_key) { 'test-secret-key' }
  let(:base_url) { 'https://cloud.tenable.com' }

  let(:client) do
    Tenable::Client.new(
      access_key: access_key,
      secret_key: secret_key,
      base_url: base_url
    )
  end
end
