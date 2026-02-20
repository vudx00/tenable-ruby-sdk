# frozen_string_literal: true

require_relative 'lib/tenable/version'

Gem::Specification.new do |spec|
  spec.name = 'tenable'
  spec.version = Tenable::VERSION
  spec.authors = ['Tenable']
  spec.summary = 'Ruby SDK for the Tenable API'
  spec.description = 'A Ruby SDK for interacting with the Tenable API, ' \
                     'covering Vulnerability Management and Web App Scanning.'
  spec.homepage = 'https://github.com/tenable/tenable-ruby-sdk'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 2.0'

  spec.add_development_dependency 'bundler-audit', '~> 0.9'
  spec.add_development_dependency 'rspec', '~> 3.12'
  spec.add_development_dependency 'rubocop', '~> 1.60'
  spec.add_development_dependency 'rubocop-performance', '~> 1.17'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.18'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
