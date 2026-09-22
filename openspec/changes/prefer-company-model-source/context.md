# Company-first Responses routing

The operator wants a company gateway tried first, with a dashboard on/off control and local-account fallback when the gateway rejects requests. Credit availability is inferred from request errors, as explicitly chosen by the operator; no balance endpoint is needed.

Use the existing model-source configuration for the base URL and encrypted API key. No credential is stored in this change. A successful HTTP status alone does not prove a well-formed completed model response, and it does not report remaining credit.

Example: an enabled preferred source supports the same model as local accounts. A fresh Responses request succeeds there and returns directly. If it returns an explicit quota rejection before content, cleanup completes and a local account is attempted. Turning the source off restores local routing for that shared model.

Requests depending on files or prior responses remain bound to their owner. Failures after partial output and ambiguous timeouts cannot safely trigger a second provider call. These limits prevent duplicate work and invalid conversation continuation.
