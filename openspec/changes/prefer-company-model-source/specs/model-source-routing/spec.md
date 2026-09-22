## ADDED Requirements

### Requirement: Optional preferred Responses source

Operators SHALL be able to opt a model source into company-first Responses routing through the dashboard. Preference SHALL default off for existing and newly created sources. An enabled preferred source supporting the requested model SHALL be tried before subscription accounts, subject to API-key model and source permissions. Disabling the source SHALL restore subscription routing for shared models. Credentials SHALL remain encrypted at rest and absent from API responses and logs.

#### Scenario: Company answers successfully
- **GIVEN** an enabled preferred source and local accounts support a requested model
- **WHEN** a fresh eligible Responses request succeeds at the source
- **THEN** the source response is returned without dispatching to local accounts

#### Scenario: Operator disables company routing
- **WHEN** the operator disables the preferred source
- **THEN** new requests for shared subscription models use the existing account selection behavior

### Requirement: Safe company rejection fallback

For a fresh movable request to a shared subscription model, a preferred source's explicit authentication, credit, or capacity rejection SHALL permit a local-account attempt before a downstream response starts. A confirmed connection failure before dispatch SHALL also permit fallback. Request errors SHALL be used to detect unavailable credit without asserting a numeric remaining balance. Ambiguous timeouts, partial responses, client payload errors, and requests requiring previous-response or file ownership SHALL NOT be replayed across providers. Failed source resources and reservations SHALL be released successfully before any replacement attempt begins. Client cancellation SHALL NOT trigger fallback.

#### Scenario: Credit rejection
- **WHEN** a preferred source rejects a fresh request with HTTP 402 or 429 before returning content
- **THEN** the system releases the source attempt and tries eligible local accounts

#### Scenario: Invalid credential rejection
- **WHEN** a preferred source rejects a fresh request with HTTP 401 or 403
- **THEN** the system attempts local routing after releasing the rejected attempt

#### Scenario: Partial response or ambiguous timeout
- **WHEN** the source has started a response or a timeout cannot establish whether it processed the request
- **THEN** the request is not replayed on a local account

#### Scenario: Bound conversation
- **WHEN** a request requires a previous response or uploaded file owner
- **THEN** the company-first option preserves existing ownership constraints

#### Scenario: Reservation release failure
- **WHEN** the rejected source reservation cannot be confirmed released
- **THEN** local fallback does not begin

### Requirement: Equivalent Responses paths preserve preference

The backend Codex and public v1 Responses routes, including trailing-slash equivalents, SHALL apply the same source preference and safe fallback policy. WebSocket clients selecting a source-backed model SHALL use the existing HTTP transport fallback mechanism rather than silently bypass the preferred source.

#### Scenario: Trailing slash
- **WHEN** a client uses a trailing-slash Responses route
- **THEN** company-first selection and fallback match the canonical route
