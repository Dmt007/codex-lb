# Model Source Routing — Context

## Purpose

Capability-based routing and accounting for OpenAI-compatible model sources,
including field-preserving embeddings forwarding.

This capability keeps source selection separate from subscription-account
routing: embeddings traffic is served only by sources that declare the
embeddings capability, while Responses/chat/audio continue to use their own
capability gates. Field presence (including explicit nulls) is preserved on
embeddings forwards so compatible sources see the same payload shape the
client sent.

## Preferred company Responses gateway

In Settings, expand Advanced and add a model source with the company base URL,
API key, Responses capability, streaming support, and the model IDs it serves.
Enable "Try this source before local accounts". The source's existing enable
switch turns the connection on or off. Preference defaults off, preserving
existing installations. Credentials use the existing encrypted source store.

For example, a company source and local accounts both serve the requested
model. A new request goes to the company first. HTTP 401, 402, 403, 429 or 503
before a response starts can fall back to local accounts after cleanup.
Connection establishment failures and the local source concurrency cap can
also fall back. This detects unavailable credit from rejection; it does not
measure or display a remaining balance.

An ambiguous timeout or a stream that has already started is not replayed.
HTTP 200 streams reporting errors later retain their existing error handling;
they do not trigger fallback. Files, previous responses and turn-state
continuity preserve their routing constraints. Disabling a source restores
local routing for shared models on unrestricted keys; explicit API-key source
and account restrictions still apply. Models unique to a source cannot fall
back to local accounts.

The gateway is contacted only for real requests. A successful status alone
does not demonstrate the remaining balance or semantic correctness of output.
