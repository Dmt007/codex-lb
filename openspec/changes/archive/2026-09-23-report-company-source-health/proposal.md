## Why
Source enablement does not indicate whether the company gateway answers requests. Operators need observed availability on the gateway card.
## What Changes
- Record completed Responses request outcomes in the existing source health field.
- Show Active, Inactive or Not checked independently of administrative enablement.
- Refresh the card automatically; reset observations when credentials or URL change.
## Capabilities
### New Capabilities
None.
### Modified Capabilities
- `model-source-routing`: observed Responses source availability.
## Impact
Responses dispatch, source repository/service and dashboard cards. No database migration.
