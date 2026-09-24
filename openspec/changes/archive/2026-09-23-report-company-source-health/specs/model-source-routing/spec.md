## ADDED Requirements

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
