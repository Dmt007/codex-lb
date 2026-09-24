## Context

The Accounts page has a narrow list column beside account details. Source management already provides add/edit/delete, enablement and Responses preference controls.

## Goals / Non-Goals

Reuse those controls in the list column without duplicating state or changing routing. Do not pretend that a gateway has an individual subscription quota.

## Decisions

Add a compact presentation to the shared component and render it below the account list. Keep dialogs and query keys shared with Settings. Only source administrators see the new section; account write permission alone does not grant source write access.

## Risks / Trade-offs

Long names and URLs can crowd the column; wrap header/actions and constrain source rows. Existing Settings access remains available.
