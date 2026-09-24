## Context

The prior compact source section was outside the account card. The screenshot identifies the existing scrolling list and Add account button.

## Goals / Non-Goals

Place gateway cards inside that list and use the same add entry point. Do not invent account quotas or duplicate persisted sources.

## Decisions

Reuse source controls through a render callback supplying cards and the create action to AccountList. Render these cards within its scroll region and forward the create action to the existing modal chooser. Settings retains its full standalone presentation.

## Risks / Trade-offs

Account status/quota sorting describes subscription accounts, not source balances. Sources retain enablement and preference controls rather than fabricated usage figures.
