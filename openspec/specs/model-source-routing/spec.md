# Model Source Routing Specification

## Purpose

Define capability-based routing and accounting for OpenAI-compatible model sources, including field-preserving embeddings forwarding.
## Requirements
### Requirement: Model sources declare an embeddings capability

Each model source MUST carry a persisted `supports_embeddings` boolean
capability flag. The flag MUST default to disabled, so a source created or
migrated without an explicit value MUST NOT be treated as embeddings-capable.
The model-source create, read, and update contracts MUST expose the flag, and
the stored value MUST survive a round trip through those contracts.

#### Scenario: existing sources default to disabled

- **GIVEN** a model source row that predates the embeddings capability
- **WHEN** the schema migration runs
- **THEN** the source reports `supports_embeddings` as disabled
- **AND** its existing chat-completions, responses, and audio-transcription
  routing is unchanged

#### Scenario: capability round-trips through the API

- **WHEN** a client creates or updates a model source with the embeddings
  capability enabled
- **THEN** reading the source back reports the capability as enabled

#### Scenario: omitted capability parses as disabled

- **WHEN** a model-source payload omits `supports_embeddings`
- **THEN** it parses as disabled rather than failing validation

### Requirement: Embeddings route only to capable model sources

The system SHALL expose `POST /v1/embeddings` and MUST serve it only from an
enabled model source of kind `openai_compatible` that declares the embeddings
capability and has the requested model enabled. Embeddings requests MUST NOT
fall back to subscription-backed accounts. When the caller presents an API key
restricted to a set of sources, selection MUST stay inside that set. Beyond
the validated `model` and `input` fields, the request payload MUST be
forwarded to the source verbatim.

#### Scenario: capable source serves the request

- **GIVEN** an enabled model source declaring the embeddings capability with
  the requested model enabled
- **WHEN** a client posts to `/v1/embeddings`
- **THEN** the proxy forwards the payload to that source's `/embeddings`
  endpoint and returns the upstream JSON response

#### Scenario: no capable source is a model error

- **GIVEN** no enabled model source declares the embeddings capability for
  the requested model
- **WHEN** a client posts to `/v1/embeddings`
- **THEN** the proxy returns 404 with an OpenAI-format error envelope using
  code `model_not_found`
- **AND** the request is not routed to a subscription-backed account

#### Scenario: source-restricted API key cannot escape its set

- **GIVEN** an API key restricted to a set of model sources
- **WHEN** the only embeddings-capable source for the model is outside that
  set
- **THEN** the proxy returns `model_not_found`

### Requirement: Embeddings requests are accounted like other source routes

Embeddings responses MUST be inspected for prompt and total token usage. When
the caller's API key requires usage for settlement and the source response
reports none, the proxy MUST fail closed with `usage_unavailable` rather than
serving unmetered traffic. Every embeddings attempt that is dispatched to a
model source MUST produce a request-log entry, with `success` on a forwarded
response and `error` on a forwarding, usage, or settlement failure. That entry
MUST carry the upstream status code when a source returned an HTTP response,
and MUST record the upstream status as absent when the attempt failed before
any response was received. A request rejected before source selection succeeds
is not a dispatched attempt: it MUST NOT produce a request-log entry, because
no source was contacted and no reservation was consumed.

#### Scenario: missing usage fails closed for a limited key

- **GIVEN** an API key whose reservation requires reported usage
- **WHEN** the model source returns an embeddings response without a usage
  object
- **THEN** the proxy returns an error envelope using code `usage_unavailable`
- **AND** records an error request log

#### Scenario: forwarding error propagates the upstream status

- **WHEN** the model source returns an error status for an embeddings request
- **THEN** the proxy returns an OpenAI-format error envelope with that status
- **AND** records an error request log carrying the upstream status code

#### Scenario: transport failure records an attempt without an upstream status

- **WHEN** the request to the model source fails before any HTTP response is
  received
- **THEN** the proxy records an error request log for the attempt with no
  upstream status code

#### Scenario: unroutable model is not a logged attempt

- **GIVEN** no enabled model source declares the embeddings capability for
  the requested model
- **WHEN** a client posts to `/v1/embeddings`
- **THEN** the proxy returns the `model_not_found` envelope without writing a
  request-log entry
- **AND** no reservation is consumed for the rejected request

### Requirement: Embeddings source forwarding preserves field presence

For source-routed `POST /v1/embeddings` requests, the system MUST preserve both
the values and presence of fields beyond the validated `model` and `input`
fields. A field explicitly supplied as null MUST be forwarded as null, a field
omitted by the client MUST remain absent, and a non-null field MUST be forwarded
unchanged. This forwarding behavior MUST NOT change reservation settlement or
request-log metadata.

#### Scenario: explicit null extras remain present

- **WHEN** a client supplies `dimensions: null` and `user: null` in a
  source-routed embeddings request
- **THEN** the compatible source receives both keys with null values

#### Scenario: omitted extras remain absent

- **WHEN** a client omits `dimensions` and `user` from a source-routed
  embeddings request
- **THEN** the compatible source payload does not contain either key

#### Scenario: non-null extras and accounting remain unchanged

- **WHEN** a client supplies non-null embedding extras through a limited API
  key
- **THEN** the compatible source receives those values unchanged
- **AND** the reservation settles from reported usage
- **AND** the successful request log retains its model-source metadata and
  token counts

### Requirement: Owner-unavailable stream health preserves the recovery cause

The service SHALL use the original upstream error code for account-health
recovery when a Responses stream rewrites an upstream failure to
`previous_response_owner_unavailable`. The rewrite MUST NOT change
source-ownership selection, owner pinning, or stale-anchor matching.

#### Scenario: Owner-unavailable rewrite records original recovery code

- **WHEN** an upstream Responses failure with an account-recovery code is
  rewritten to `previous_response_owner_unavailable`
- **THEN** account health receives the original upstream code
- **AND** source ownership and stale-anchor classification remain unchanged

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

### Requirement: Source management alongside accounts

The Accounts page SHALL expose source creation, editing, enablement and Responses preference controls beside the account list for authorized source administrators. It SHALL operate on the same source records as Settings. Account administration permission alone SHALL NOT grant source administration access. The controls SHALL remain usable in the narrow account column and on mobile.

#### Scenario: Operator manages company gateway from Accounts
- **WHEN** a source administrator opens Accounts
- **THEN** source controls appear in the account list column and allow adding or editing a gateway and changing its enablement and preference

#### Scenario: Existing source is shared
- **WHEN** a source previously created in Settings is viewed in Accounts
- **THEN** the same source and settings are shown without importing a duplicate

#### Scenario: Restricted account administrator
- **WHEN** an account administrator lacks source write permission
- **THEN** the Accounts page does not expose the source administration section

### Requirement: Gateway cards share the account list and add chooser

For source administrators, gateway cards SHALL appear inside the same scrolling list as subscription account cards, not in a separate panel below the list. Add account SHALL offer a company gateway option opening the existing source creation form. Source editing, enablement and preference SHALL remain available on the gateway cards. Settings SHALL continue using the same stored sources. Restricted operators SHALL NOT receive source administration controls.

#### Scenario: Gateway in account card list
- **WHEN** a source administrator opens Accounts with a saved gateway
- **THEN** its card is inside the account list scroll region with its existing source controls

#### Scenario: Add company gateway
- **WHEN** the administrator chooses Company gateway in Add account
- **THEN** the chooser closes and the source creation dialog opens

### Requirement: Gateway availability reflects completed Responses attempts

Source cards SHALL show Active after successful Responses completion, Inactive after upstream authentication, quota, server or connection failure, and Not checked before an observation. This status SHALL be independent of administrative enablement and SHALL NOT exclude a source from retries. Client cancellation, invalid client payloads and local accounting errors SHALL NOT mark a source inactive. Health writes SHALL follow reservation cleanup and SHALL NOT run if cleanup failed. Updating URL or credentials SHALL reset health to unknown; outcomes from the old configuration SHALL NOT update the new configuration. The dashboard SHALL refresh observations within 15 seconds while visible. The status SHALL describe the last observed request rather than a live balance or periodic probe.

#### Scenario: Recovery
- **WHEN** a source fails authentication and later completes a Responses request successfully
- **THEN** its status changes from Inactive to Active

#### Scenario: Cancellation
- **WHEN** a client cancels its request
- **THEN** the source retains its previous health status

#### Scenario: Credentials changed during request
- **WHEN** a source's credentials change while an old request finishes
- **THEN** the old request does not overwrite the reset health status
