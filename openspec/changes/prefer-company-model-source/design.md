## Context

See proposal.md for motivation. ModelSource already stores encrypted credentials, a base URL, capabilities, models, and an enable switch. Responses source dispatch owns transport cleanup, API-key settlement, and request logging. Selection currently skips sources for known subscription models.

## Goals / Non-Goals

Goals: reuse source configuration and dispatch; add explicit preference and bounded local fallback; preserve existing account/file/continuity constraints.

Non-goals: balance polling, numeric credit reporting, replaying ambiguous failures, transparent cross-provider conversation migration, and a separate network proxy implementation.

## Decisions

Add a persisted prefer-for-responses boolean, default false, exposed by source schemas and dashboard controls. Keep source enablement as the overall on/off switch. This avoids new environment settings and another credential store.

Only preferred sources override subscription precedence. API-key permissions continue to constrain selection. Sources with unique models retain existing behavior, because local accounts cannot serve those models.

For eligible fresh requests, source dispatch signals a safe fallback only after rejection cleanup succeeds. Route handlers retain their original normalized subscription payload so source-specific shaping does not leak into fallback. Explicit HTTP 401/402/403/429/503 rejections are eligible; arbitrary payload errors, ambiguous timeouts, and partial streams are not. HTTP 200 SSE terminal errors retain existing error handling after the downstream response starts and do not trigger replay.

Reuse the existing WebSocket source ownership guard to move eligible source requests to HTTP. Preserve file and previous-response constraints before selection and before fallback.

## Risks / Trade-offs

- A failed company call adds latency: retain bounded source connection/header deadlines.
- Unknown error formats: do not infer credit from arbitrary text or claim a balance value.
- Cross-provider replay: restrict fallback to fresh movable requests and explicit rejection evidence.
- Reservation cleanup failure: fail closed before a second reservation or dispatch.

## Migration Plan

Add a false-default boolean on the current Alembic head, covering existing rows. Rollback removes the preference after reverting application code. Configure credentials through the existing protected source dashboard, never in migration data.
