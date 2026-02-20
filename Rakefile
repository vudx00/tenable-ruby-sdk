# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:rubocop)

task default: %i[spec rubocop]

desc 'Bump version: rake bump[patch|minor|major]'
task :bump, [:level] do |_t, args|
  level = args[:level] || 'patch'
  version_file = File.join(__dir__, 'lib', 'tenable', 'version.rb')
  content = File.read(version_file)
  current = content.match(/VERSION = '(\d+)\.(\d+)\.(\d+)'/)
  abort 'Could not parse version' unless current

  major = current[1].to_i
  minor = current[2].to_i
  patch = current[3].to_i

  case level
  when 'major'
    major += 1
    minor = 0
    patch = 0
  when 'minor'
    minor += 1
    patch = 0
  when 'patch'
    patch += 1
  else abort "Unknown level '#{level}'. Use patch, minor, or major."
  end

  new_version = "#{major}.#{minor}.#{patch}"
  File.write(version_file, content.sub(/VERSION = '.*'/, "VERSION = '#{new_version}'"))
  puts "Bumped to #{new_version}"
end
