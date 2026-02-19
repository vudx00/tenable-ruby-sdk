# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-19

### Added

- Client with API key authentication (direct parameters or environment variables)
- Thread-safe, frozen client instances
- Custom Faraday middleware stack: authentication, retry with exponential backoff, logging with key redaction
- TLS enforcement for all connections
- Error hierarchy with actionable messages (`AuthenticationError`, `ApiError`, `RateLimitError`, `ConnectionError`, `TimeoutError`, `ParseError`)
- Vulnerability management: list vulnerabilities with transparent lazy pagination
- Export workflow: initiate exports, poll status, download chunks, iterate results
- VM scan operations: list, create, launch, check status
- WAS v2 scan operations: create config, launch scan, check status, retrieve findings, wait for completion
- Typed model objects: `Asset`, `Vulnerability`, `Export`, `Scan`, `WebAppScanConfig`, `WebAppScan`, `Finding`
- Configuration validation (credential presence, HTTPS enforcement, timeout bounds, retry limits)
- Rate limit handling with automatic retry and Retry-After header support
