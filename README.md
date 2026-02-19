# tenable-ruby-sdk

Ruby client for the [Tenable.io API](https://developer.tenable.com/reference/navigate). Covers vulnerability management, bulk exports, VM scans, and WAS v2 web application scanning.

Requires Ruby >= 3.1. Uses [Faraday](https://github.com/lostisland/faraday) for HTTP.

## Installation

Add to your Gemfile:

```ruby
gem 'tenable-ruby-sdk'
```

Then `bundle install`.

## Authentication

Get your API keys from Tenable.io under **Settings > My Account > API Keys**.

Pass them directly:

```ruby
client = Tenable::Client.new(
  access_key: "your-access-key",
  secret_key: "your-secret-key"
)
```

Or set environment variables and omit them:

```sh
export TENABLE_ACCESS_KEY="your-access-key"
export TENABLE_SECRET_KEY="your-secret-key"
```

```ruby
client = Tenable::Client.new
```

## Usage

### List Vulnerabilities

```ruby
data = client.vulnerabilities.list
data["vulnerabilities"].each do |vuln|
  puts "#{vuln['plugin_name']} (severity: #{vuln['severity']})"
end
```

### Export Vulnerabilities

For large datasets, use the export workflow:

```ruby
exports = client.exports

# Start the export
result = exports.export(num_assets: 50)
uuid = result["export_uuid"]

# Wait for it to finish (polls automatically, 5 min timeout by default)
exports.wait_for_completion(uuid)

# Iterate over all chunks
exports.each(uuid) do |vuln|
  puts vuln["plugin"]["name"]
end
```

### VM Scans

```ruby
# List scans
client.scans.list

# Launch a scan
client.scans.launch(scan_id)

# Check status
client.scans.status(scan_id)
```

### Web App Scans (WAS v2)

```ruby
was = client.web_app_scans

# Create a scan config
config = was.create_config(name: "My Scan", target: "https://example.com")
config_id = config["config_id"]

# Launch the scan
scan = was.launch(config_id)
scan_id = scan["scan_id"]

# Wait for completion (polls until terminal status)
was.wait_until_complete(config_id, scan_id)

# Get findings
was.findings(config_id)
```

## Configuration

All options with their defaults:

```ruby
client = Tenable::Client.new(
  access_key:   "...",                          # or TENABLE_ACCESS_KEY env var
  secret_key:   "...",                          # or TENABLE_SECRET_KEY env var
  base_url:     "https://cloud.tenable.com",    # must be HTTPS
  timeout:      30,                             # request timeout (seconds)
  open_timeout: 10,                             # connection timeout (seconds)
  max_retries:  3,                              # retry attempts (0-10)
  logger:       Logger.new($stdout)             # nil = silent (default)
)
```

## Error Handling

All errors inherit from `Tenable::Error`:

```ruby
begin
  client.vulnerabilities.list
rescue Tenable::AuthenticationError => e
  # Bad or missing API keys (401)
rescue Tenable::RateLimitError => e
  # Rate limited and retries exhausted (429)
  e.status_code  # => 429
rescue Tenable::TimeoutError => e
  # Request or export poll timed out
rescue Tenable::ApiError => e
  # Any other API error
  e.status_code  # => Integer
  e.body         # => String
rescue Tenable::ConnectionError => e
  # Network failure
end
```

Rate limiting (429) and server errors (5xx) are retried automatically with exponential backoff before raising.

## Thread Safety

The client is frozen after initialization. Each call to a resource accessor (e.g., `client.vulnerabilities`) returns a new instance, so there's no shared mutable state. Safe to use across threads.

## Development

```sh
bundle install
bundle exec rspec        # run tests
bundle exec rubocop      # lint
bundle exec yard doc     # generate docs
bundle audit check       # check for vulnerable dependencies
```

## License

MIT
