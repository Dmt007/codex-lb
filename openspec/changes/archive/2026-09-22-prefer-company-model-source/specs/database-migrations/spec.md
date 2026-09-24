## ADDED Requirements

### Requirement: Historical timestamp collision retains deployed revision identities

Migration topology validation SHALL accept the historical timestamp collision between `20260914_000000_add_scim_tokens` and `20260914_000000_drop_subscription_overflow_schema` only when these are the entire collision group, both retain parent `20260913_000000_add_oidc_provider_flow`, and `20260922_000000_preferred_responses_source` directly merges exactly these two revisions. It SHALL continue enforcing graph connectivity, identity, single-head and new-collision checks independently. Historical revision IDs SHALL remain unchanged.

#### Scenario: Existing collision has its corrective merge
- **WHEN** the exact historical pair and corrective merge are present in a valid single-head graph
- **THEN** timestamp validation accepts the known collision without rewriting either revision

#### Scenario: New revision reuses the historical slot
- **WHEN** any third revision shares the historical timestamp
- **THEN** validation rejects the collision

#### Scenario: Corrective merge is missing or changed
- **WHEN** the named corrective merge is absent or does not directly merge exactly the historical pair
- **THEN** validation rejects the historical collision
