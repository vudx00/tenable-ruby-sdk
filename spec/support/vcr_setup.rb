# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = File.join(__dir__, '..', 'cassettes')
  config.hook_into :webmock
  config.configure_rspec_metadata!

  config.filter_sensitive_data('<ACCESS_KEY>') { ENV.fetch('TENABLE_ACCESS_KEY', 'test-access-key') }
  config.filter_sensitive_data('<SECRET_KEY>') { ENV.fetch('TENABLE_SECRET_KEY', 'test-secret-key') }

  config.default_cassette_options = {
    record: :none,
    match_requests_on: %i[method uri body]
  }
end
