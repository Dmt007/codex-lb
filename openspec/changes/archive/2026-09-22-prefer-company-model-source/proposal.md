## Why

Operators need to use an existing company Codex gateway before local subscription accounts, with an on/off control. Current model-source selection gives subscription models precedence and does not fall back to subscription accounts after a source rejection.

## What Changes

- Add an opt-in source preference for Responses requests, configurable in the existing model-source dashboard section.
- Reuse encrypted source credentials, base URL, model capabilities, and the source enable/disable switch.
- Infer invalid credentials, exhausted credit, and capacity rejection from request errors; do not poll a balance endpoint or claim to know remaining credit.
- Fall back to local accounts only for eligible fresh requests after an explicit retryable rejection or confirmed pre-dispatch connection failure, before any response content is sent.
- Preserve file ownership, conversation continuity, API-key scope and reservation settlement on both attempts.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `model-source-routing`: opt-in company-first Responses selection and safe subscription fallback with dashboard controls.
- `database-migrations`: preserve the already merged September 14 revision IDs with an exact, merge-gated historical timestamp exception; continue rejecting new collisions.

## Impact

Model-source persistence, schemas, selection, Responses HTTP dispatch, WebSocket transport selection, dashboard source controls, and route-level regression coverage. Existing sources retain their routing behavior by default. No credentials are embedded in repository files.
