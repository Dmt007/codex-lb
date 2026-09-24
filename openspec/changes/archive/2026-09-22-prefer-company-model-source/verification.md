# Verification

Implementation covers optional source precedence, existing source enablement,
credential-safe configuration, explicit HTTP rejection fallback, confirmed
connector failures, and source admission saturation. Both Responses HTTP
surfaces preserve subscription payloads and wait for source cleanup before
fallback. The existing WebSocket source guard remains in use.

## Evidence

- Route tests cover HTTP 401/402/403/429/503, non-retryable 400, streaming and
  non-streaming, backend and v1 routes with and without trailing slashes,
  source disablement, successful source responses, ambiguous timeout,
  failed cleanup, actual limited-key reservation release, previous-response,
  turn-state and file ownership.
- Existing model-source routing, dispatch, service and WebSocket suites pass.
- TypeScript build check and all 18 model-source frontend tests pass.
- Real Chrome UI check verifies that toggling preference submits and displays
  the changed setting. Screenshots: `screenshots/preference-off.png` and
  `screenshots/preference-on.png`. These use fixture data, not a live company
  connection. Browser download was region-blocked; installed Chrome was used.
- SQLite migration regression covers historical false defaults, repeated
  upgrade, downgrade and re-upgrade without losing the historical row.
- Ruff and strict OpenSpec change validation pass. Main specs have been synced.

## Resolved repository gate

The checkout originally contained two migration heads with the same timestamp:
`20260914_000000_add_scim_tokens` and
`20260914_000000_drop_subscription_overflow_schema`. The new revision merges
them and restores one head. The topology checker now recognizes only this exact
historical pair, with its original parent and exact corrective merge. Third
revisions, changed parents, missing merges and changed merges remain errors.
Historical migration files were not rewritten. `make` is unavailable in this
Windows environment; every command from its lint and architecture-check targets
was run directly and passed. Two pre-existing formatting issues in
`test_windows_desktop_controller.py` were fixed without behavioral changes.

Additional verification: 30 migration/topology tests passed. A fresh isolated
SQLite database upgraded through the full migration chain to
`20260922_000000_preferred_responses_source`; `codex-lb-db check` returned
`migration_policy=ok` and `schema_drift=none`. Pytest's default Windows temporary
directory was inaccessible; tests passed with a fresh explicit temporary path.
No application database was used. Local verification is complete; no GitHub
merge/CI readiness claim is made.

## Operational limits

No live company request was made, no credential was saved, and no running
deployment or database was modified. Configure source models and credentials
through the existing dashboard after upgrading. HTTP 200 SSE errors after
response start and ambiguous post-dispatch failures do not trigger replay.
The option does not provide a numeric credit balance or guarantee the semantic
correctness of generated output. Source/account permissions still apply.
