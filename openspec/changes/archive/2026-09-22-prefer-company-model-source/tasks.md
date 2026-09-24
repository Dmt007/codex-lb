## 1. Source configuration

- [x] 1.0 Resolve historical timestamp collision with an exact merge-gated exception; prove new collisions and missing/changed merges still fail.
- [x] 1.1 Add false-default persisted Responses preference on the current migration head; verify upgrade/downgrade and migration topology.
- [x] 1.2 Expose preference through source API and existing dashboard source controls; verify API round-trip, secret omission, frontend type checks, and screenshots of off/on states.

## 2. Routing and fallback

- [x] 2.1 Prefer enabled eligible company sources for shared Responses models while preserving permissions and disabled-source behavior; verify selection and WebSocket guard regression tests.
- [x] 2.2 Implement explicit-rejection and pre-dispatch fallback after confirmed resource cleanup, preserving original subscription payload and ownership; verify canonical and trailing-slash route tests, invalid credentials/quota/capacity cases, and no replay after partial/ambiguous failure.
- [x] 2.3 Cover limited-key settlement, cancellation, cleanup failure, and pinned conversation/file cases through route-level regression tests.

## 3. Verification and documentation

- [x] 3.1 Run relevant backend/frontend checks and strict OpenSpec validation; record actual results and limitations.
- [x] 3.2 Sync stable requirements/context and archive only after implementation verification passes.
