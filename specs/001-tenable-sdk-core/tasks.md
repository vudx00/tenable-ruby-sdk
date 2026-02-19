# Tasks: Tenable Ruby SDK Core

**Input**: Design documents from `/specs/001-tenable-sdk-core/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: TDD is NON-NEGOTIABLE per constitution. All tests written first, confirmed to fail, then implemented.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Gem source**: `lib/tenable/` at repository root
- **Tests**: `spec/` at repository root (unit/, integration/, contract/)
- Standard RubyGem layout per plan.md

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization, gem skeleton, tooling configuration

- [X] T001 Create gem directory structure per plan.md: `lib/tenable/`, `lib/tenable/middleware/`, `lib/tenable/resources/`, `lib/tenable/models/`, `spec/unit/tenable/`, `spec/unit/tenable/middleware/`, `spec/unit/tenable/resources/`, `spec/unit/tenable/models/`, `spec/integration/`, `spec/contract/`, `spec/support/`
- [X] T002 Create `tenable.gemspec` with gem metadata, Ruby >= 3.1 requirement, Faraday (~> 2.0) runtime dependency, and development dependencies (rspec, vcr, webmock, rubocop, rubocop-rspec, rubocop-performance, yard, bundler-audit)
- [X] T003 Create `Gemfile` sourcing rubygems.org and loading gemspec
- [X] T004 [P] Create `lib/tenable/version.rb` with `Tenable::VERSION = "0.1.0"`
- [X] T005 [P] Create `.rubocop.yml` with rubocop-rspec and rubocop-performance extensions, 15-line method limit, 150-line class limit, cyclomatic complexity max 7
- [X] T006 [P] Create `.rspec` with `--format documentation --color --require spec_helper`
- [X] T007 [P] Create `Rakefile` with default task running rspec then rubocop
- [X] T008 Create `spec/spec_helper.rb` with RSpec configuration, SimpleCov (if desired), and require of `tenable`
- [X] T009 [P] Create `spec/support/vcr_setup.rb` with VCR configuration: cassette library dir, WebMock hook, filter sensitive data (access_key, secret_key)
- [X] T010 [P] Create `spec/support/shared_contexts.rb` with shared context for authenticated client (stubbed credentials)
- [X] T011 Run `bundle install` to verify gem dependencies resolve

**Checkpoint**: Gem skeleton complete, `bundle exec rspec` runs (0 examples), `bundle exec rubocop` passes.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

### Tests for Foundational

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T012 [P] Write unit tests for Error hierarchy in `spec/unit/tenable/error_spec.rb`: test `Tenable::Error` base class, `AuthenticationError`, `ApiError` (with status_code, message), `RateLimitError`, `ConnectionError`, `TimeoutError`, `ParseError` subclasses
- [X] T013 [P] Write unit tests for Configuration in `spec/unit/tenable/configuration_spec.rb`: test credential resolution (direct params > env vars), defaults (base_url, timeout, open_timeout, max_retries), validation (non-empty keys, HTTPS base_url, positive timeouts, max_retries 0-10), immutability after creation
- [X] T014 [P] Write unit tests for Authentication middleware in `spec/unit/tenable/middleware/authentication_spec.rb`: test X-ApiKeys header injection with correct format, key redaction in inspect/to_s
- [X] T015 [P] Write unit tests for Retry middleware in `spec/unit/tenable/middleware/retry_spec.rb`: test retry on 429 with Retry-After header, retry on 5xx with exponential backoff, max 3 attempts, no retry on 4xx (except 429), raises final error with attempt count after exhaustion
- [X] T016 [P] Write unit tests for Logging middleware in `spec/unit/tenable/middleware/logging_spec.rb`: test silent by default (nil logger), logs request/response at debug level when logger provided, redacts API keys from log output, logs errors at error level
- [X] T017 [P] Write unit tests for Connection in `spec/unit/tenable/connection_spec.rb`: test Faraday connection builder with middleware stack (auth, retry, logging), TLS enforcement, timeout configuration, persistent connections

### Implementation for Foundational

- [X] T018 Create error hierarchy in `lib/tenable/error.rb`: `Tenable::Error < StandardError`, `AuthenticationError`, `ApiError` (attr: status_code, body), `RateLimitError < ApiError`, `ConnectionError`, `TimeoutError`, `ParseError` — all with actionable messages, API keys never in messages
- [X] T019 Create Configuration in `lib/tenable/configuration.rb`: immutable value object with credential resolution (direct > env vars `TENABLE_ACCESS_KEY`/`TENABLE_SECRET_KEY`), defaults, validation per data-model.md rules, frozen after initialization
- [X] T020 [P] Create Authentication middleware in `lib/tenable/middleware/authentication.rb`: Faraday middleware injecting `X-ApiKeys: accessKey={KEY};secretKey={SECRET};` header, key redaction in inspect
- [X] T021 [P] Create Retry middleware in `lib/tenable/middleware/retry.rb`: Faraday middleware with exponential backoff on 429/5xx, respects Retry-After header, max 3 attempts, raises with attempt context on exhaustion
- [X] T022 [P] Create Logging middleware in `lib/tenable/middleware/logging.rb`: Faraday middleware, silent when logger nil, debug-level request/response logging, error-level for failures, API key redaction in all output
- [X] T023 Create Connection builder in `lib/tenable/connection.rb`: builds Faraday connection with middleware stack (authentication, retry, logging), enforces HTTPS/TLS, applies timeout/open_timeout from configuration, persistent adapter
- [X] T024 Create gem entry point in `lib/tenable.rb`: require all files, define `Tenable` module with autoloads
- [X] T025 Run `bundle exec rspec spec/unit/tenable/error_spec.rb spec/unit/tenable/configuration_spec.rb spec/unit/tenable/middleware/ spec/unit/tenable/connection_spec.rb` — all tests MUST pass
- [X] T026 Run `bundle exec rubocop` — zero warnings

**Checkpoint**: Foundation ready — error handling, configuration, authentication, retry, logging, and connection infrastructure all tested and working. User story implementation can now begin.

---

## Phase 3: User Story 1 — SDK Authentication & Client Setup (Priority: P1) MVP

**Goal**: Developer can create a Client with API keys (direct or env vars) and make authenticated requests. Thread-safe, configurable, with actionable errors.

**Independent Test**: Create client with valid keys, confirm authenticated request succeeds. Create client with invalid keys, confirm actionable error raised.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T027 [P] [US1] Write unit tests for Client in `spec/unit/tenable/client_spec.rb`: test initialization with direct keys, initialization from env vars, missing credentials error, resource accessors (vulnerabilities, exports, scans, web_app_scans), thread safety (frozen state, no shared mutable data), logger configuration, custom base_url/timeout
- [X] T028 [P] [US1] Write contract test for authentication in `spec/contract/vulnerability_api_spec.rb`: test GET /workbenches/vulnerabilities with valid auth returns 200, invalid auth returns 401 with actionable error (use VCR cassette)
- [X] T029 [P] [US1] Write integration test for authentication workflow in `spec/integration/authentication_spec.rb`: test full client creation → authenticated request → successful response, invalid credentials → AuthenticationError, revoked credentials → AuthenticationError with guidance, missing credentials → configuration error listing expected sources

### Implementation for User Story 1

- [X] T030 [US1] Create Client in `lib/tenable/client.rb`: initialize with Configuration, build Connection, expose resource accessors (lazy-loaded), freeze after initialization for thread safety, accept optional logger
- [X] T031 [US1] Run `bundle exec rspec spec/unit/tenable/client_spec.rb spec/contract/vulnerability_api_spec.rb spec/integration/authentication_spec.rb` — all US1 tests MUST pass
- [X] T032 [US1] Run `bundle exec rubocop lib/tenable/client.rb` — zero warnings

**Checkpoint**: User Story 1 complete. Developer can `Tenable::Client.new(access_key: "...", secret_key: "...")` and make authenticated API calls. Thread-safe. Actionable errors on auth failure.

---

## Phase 4: User Story 2 — Vulnerability Management Operations (Priority: P2)

**Goal**: Developer can list, filter, and export vulnerabilities. Pagination is transparent (lazy Enumerator). Rate limiting and retries handled automatically. Response objects are typed and attribute-accessible.

**Independent Test**: List vulnerabilities, filter by severity, initiate export, iterate results — all without manual pagination or rate-limit handling.

### Tests for User Story 2

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T033 [P] [US2] Write unit tests for Pagination in `spec/unit/tenable/pagination_spec.rb`: test lazy Enumerator for offset/limit, auto-fetches next page when offset < total, stops when offset >= total, handles empty page gracefully, max page size 200
- [X] T034 [P] [US2] Write unit tests for Vulnerability model in `spec/unit/tenable/models/vulnerability_spec.rb`: test attribute accessors (plugin_id, plugin_name, severity, state, asset, vpr_score, cve, etc.), nil defaults for missing attributes, embedded Asset model with its attributes
- [X] T035 [P] [US2] Write unit tests for Export model in `spec/unit/tenable/models/export_spec.rb`: test attribute accessors (uuid, status, chunks_available, chunks_failed), state values (QUEUED, PROCESSING, FINISHED, ERROR, CANCELLED), status helper methods (finished?, processing?, error?)
- [X] T036 [P] [US2] Write unit tests for Vulnerabilities resource in `spec/unit/tenable/resources/vulnerabilities_spec.rb`: test list returns paginated Enumerator of Vulnerability objects, list with severity filter, list handles empty results
- [X] T037 [P] [US2] Write unit tests for Exports resource in `spec/unit/tenable/resources/exports_spec.rb`: test export initiates POST /vulns/export, status polling, chunk download, each yields Vulnerability objects across all chunks, timeout raises TimeoutError with export UUID
- [X] T038 [P] [US2] Write contract test for vulnerability endpoints in `spec/contract/export_api_spec.rb`: test POST /vulns/export request shape, GET /vulns/export/{uuid}/status response shape, GET /vulns/export/{uuid}/chunks/{id} response shape (use VCR cassettes)
- [X] T039 [P] [US2] Write integration test for vulnerability workflow in `spec/integration/vulnerability_workflow_spec.rb`: test list → iterate → verify objects, filter by severity → verify filtered results
- [X] T040 [P] [US2] Write integration test for export workflow in `spec/integration/export_workflow_spec.rb`: test initiate export → poll status → download chunks → iterate results, export timeout → TimeoutError with UUID

### Implementation for User Story 2

- [X] T041 [US2] Create Pagination in `lib/tenable/pagination.rb`: lazy Enumerator wrapping offset/limit pagination, auto-fetches next page, stops at total, handles empty pages, enforces max page size 200
- [X] T042 [P] [US2] Create Vulnerability model in `lib/tenable/models/vulnerability.rb`: value object with all attributes from data-model.md, nil defaults for missing fields, embedded Asset object
- [X] T043 [P] [US2] Create Asset model in `lib/tenable/models/asset.rb`: value object with uuid, hostname, ipv4, operating_system, fqdn, netbios_name
- [X] T044 [P] [US2] Create Export model in `lib/tenable/models/export.rb`: value object with uuid, status, chunks_available/failed/cancelled, status helper methods (finished?, processing?, error?)
- [X] T045 [US2] Create Vulnerabilities resource in `lib/tenable/resources/vulnerabilities.rb`: list method returning paginated Enumerator of Vulnerability objects, severity filter support, uses Connection for HTTP
- [X] T046 [US2] Create Exports resource in `lib/tenable/resources/exports.rb`: export method (POST initiate, poll status with backoff, download chunks), each method yielding Vulnerability objects, configurable poll timeout, raises TimeoutError with export UUID on timeout
- [X] T047 [US2] Wire Vulnerabilities and Exports resources into Client (`lib/tenable/client.rb`): add `vulnerabilities` and `exports` accessor methods
- [X] T048 [US2] Run `bundle exec rspec spec/unit/tenable/pagination_spec.rb spec/unit/tenable/models/vulnerability_spec.rb spec/unit/tenable/models/export_spec.rb spec/unit/tenable/resources/vulnerabilities_spec.rb spec/unit/tenable/resources/exports_spec.rb spec/contract/export_api_spec.rb spec/integration/vulnerability_workflow_spec.rb spec/integration/export_workflow_spec.rb` — all US2 tests MUST pass
- [X] T049 [US2] Run `bundle exec rubocop lib/tenable/pagination.rb lib/tenable/models/ lib/tenable/resources/vulnerabilities.rb lib/tenable/resources/exports.rb` — zero warnings

**Checkpoint**: User Story 2 complete. Developer can `client.vulnerabilities.list`, filter by severity, iterate with auto-pagination, and export large datasets — all without manual pagination or retry logic.

---

## Phase 5: User Story 3 — Web App Scanning Operations (Priority: P3)

**Goal**: Developer can create WAS v2 scan configurations, launch scans, monitor status, and retrieve findings. Async config creation handled transparently.

**Independent Test**: Create scan config, launch scan, check status, retrieve findings — all via simple method calls.

### Tests for User Story 3

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T050 [P] [US3] Write unit tests for Scan model in `spec/unit/tenable/models/scan_spec.rb`: test VM Scan attributes (id, uuid, name, status, folder_id, type, creation_date, last_modification_date)
- [X] T051 [P] [US3] Write unit tests for WebAppScanConfig model in `spec/unit/tenable/models/web_app_scan_config_spec.rb`: test attributes (config_id, name, target, status, tracking_id)
- [X] T052 [P] [US3] Write unit tests for WebAppScan model in `spec/unit/tenable/models/web_app_scan_spec.rb`: test attributes (scan_id, config_id, status, started_at, completed_at, findings_count)
- [X] T053 [P] [US3] Write unit tests for Finding model in `spec/unit/tenable/models/finding_spec.rb`: test attributes (finding_id, severity, url, name, description, remediation, plugin_id)
- [X] T054 [P] [US3] Write unit tests for Scans resource in `spec/unit/tenable/resources/scans_spec.rb`: test list scans, create scan, launch scan, get status (uses VM scan endpoints)
- [X] T055 [P] [US3] Write unit tests for WebAppScans resource in `spec/unit/tenable/resources/web_app_scans_spec.rb`: test create_config (async POST → poll tracking → return config), launch scan, get status, list findings with pagination, wait_until_complete helper
- [X] T056 [P] [US3] Write contract tests for scan endpoints in `spec/contract/scan_api_spec.rb`: test GET /scans, POST /scans, POST /scans/{id}/launch, GET /scans/{id}/latest-status request/response shapes (VCR)
- [X] T057 [P] [US3] Write contract tests for WAS endpoints in `spec/contract/web_app_scan_api_spec.rb`: test POST /was/v2/configs (202 + Location), GET /was/v2/configs/{id}/status/{tracking_id}, POST /was/v2/configs/{id}/scans, POST /was/v2/configs/{id}/scans/search request/response shapes (VCR)
- [X] T058 [P] [US3] Write integration test for web app scan workflow in `spec/integration/web_app_scan_workflow_spec.rb`: test create config → launch → poll status → retrieve findings end-to-end

### Implementation for User Story 3

- [X] T059 [P] [US3] Create Scan model in `lib/tenable/models/scan.rb`: value object with all VM scan attributes from data-model.md
- [X] T060 [P] [US3] Create WebAppScanConfig model in `lib/tenable/models/web_app_scan_config.rb`: value object with config_id, name, target, status, tracking_id
- [X] T061 [P] [US3] Create WebAppScan model in `lib/tenable/models/web_app_scan.rb`: value object with scan_id, config_id, status, started_at, completed_at, findings_count
- [X] T062 [P] [US3] Create Finding model in `lib/tenable/models/finding.rb`: value object with finding_id, severity, url, name, description, remediation, plugin_id
- [X] T063 [US3] Create Scans resource in `lib/tenable/resources/scans.rb`: list (GET /scans), create (POST /scans), launch (POST /scans/{id}/launch), status (GET /scans/{id}/latest-status), returns Scan objects
- [X] T064 [US3] Create WebAppScans resource in `lib/tenable/resources/web_app_scans.rb`: create_config (async POST /was/v2/configs → poll tracking → return WebAppScanConfig), launch (POST /was/v2/configs/{id}/scans), status, findings (paginated), wait_until_complete helper
- [X] T065 [US3] Wire Scans and WebAppScans resources into Client (`lib/tenable/client.rb`): add `scans` and `web_app_scans` accessor methods
- [X] T066 [US3] Run `bundle exec rspec spec/unit/tenable/models/scan_spec.rb spec/unit/tenable/models/web_app_scan_config_spec.rb spec/unit/tenable/models/web_app_scan_spec.rb spec/unit/tenable/models/finding_spec.rb spec/unit/tenable/resources/scans_spec.rb spec/unit/tenable/resources/web_app_scans_spec.rb spec/contract/scan_api_spec.rb spec/contract/web_app_scan_api_spec.rb spec/integration/web_app_scan_workflow_spec.rb` — all US3 tests MUST pass
- [X] T067 [US3] Run `bundle exec rubocop lib/tenable/models/scan.rb lib/tenable/models/web_app_scan_config.rb lib/tenable/models/web_app_scan.rb lib/tenable/models/finding.rb lib/tenable/resources/scans.rb lib/tenable/resources/web_app_scans.rb` — zero warnings

**Checkpoint**: User Story 3 complete. Developer can create WAS configs, launch scans, monitor status, and retrieve findings via simple method calls.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T068 [P] Add YARD documentation (@param, @return, @raise) to all public methods in `lib/tenable/client.rb`, `lib/tenable/resources/*.rb`
- [X] T069 [P] Add YARD documentation to all model classes in `lib/tenable/models/*.rb`
- [X] T070 Run `bundle exec rubocop` on entire codebase — zero warnings
- [X] T071 Run `bundle exec rspec` full suite — all tests pass, verify coverage >= 90%
- [X] T072 Run `bundle audit check --update` — zero known vulnerabilities
- [X] T073 Validate quickstart.md examples against actual SDK API (manual review)
- [X] T074 [P] Create `CHANGELOG.md` with v0.1.0 entry documenting initial release features

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion — BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational — BLOCKS US2 and US3 (Client needed)
- **User Story 2 (Phase 4)**: Depends on US1 (needs working Client)
- **User Story 3 (Phase 5)**: Depends on US1 (needs working Client); independent of US2
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) — no other story dependencies
- **User Story 2 (P2)**: Depends on US1 Client — uses Pagination (new in US2) + Vulnerability/Export models
- **User Story 3 (P3)**: Depends on US1 Client — uses Pagination from US2 for WAS scan search; can start after US2 or in parallel if Pagination extracted during US2

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before resources
- Resources before Client wiring
- All tests pass before checkpoint

### Parallel Opportunities

- Setup: T004, T005, T006, T007 can all run in parallel
- Setup: T009, T010 can run in parallel
- Foundational tests: T012-T017 can all run in parallel
- Foundational implementation: T020, T021, T022 can run in parallel
- US1 tests: T027, T028, T029 can run in parallel
- US2 tests: T033-T040 can all run in parallel
- US2 models: T042, T043, T044 can run in parallel
- US3 tests: T050-T058 can all run in parallel
- US3 models: T059, T060, T061, T062 can run in parallel
- Polish: T068, T069, T074 can run in parallel

---

## Parallel Example: User Story 2

```bash
# Launch all US2 tests together (write first, must fail):
Task: "Unit tests for Pagination in spec/unit/tenable/pagination_spec.rb"
Task: "Unit tests for Vulnerability model in spec/unit/tenable/models/vulnerability_spec.rb"
Task: "Unit tests for Export model in spec/unit/tenable/models/export_spec.rb"
Task: "Unit tests for Vulnerabilities resource in spec/unit/tenable/resources/vulnerabilities_spec.rb"
Task: "Unit tests for Exports resource in spec/unit/tenable/resources/exports_spec.rb"

# Launch all US2 models together:
Task: "Vulnerability model in lib/tenable/models/vulnerability.rb"
Task: "Asset model in lib/tenable/models/asset.rb"
Task: "Export model in lib/tenable/models/export.rb"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Client authenticates, errors are actionable, thread-safe
5. Gem is installable and usable for basic authenticated requests

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → MVP: authenticated client
3. Add User Story 2 → Test independently → Vuln listing + exports
4. Add User Story 3 → Test independently → WAS scan lifecycle
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once US1 complete:
   - Developer A: User Story 2
   - Developer B: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- TDD is NON-NEGOTIABLE: verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
