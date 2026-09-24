## ADDED Requirements

### Requirement: Source management alongside accounts

The Accounts page SHALL expose source creation, editing, enablement and Responses preference controls beside the account list for authorized source administrators. It SHALL operate on the same source records as Settings. Account administration permission alone SHALL NOT grant source administration access. The controls SHALL remain usable in the narrow account column and on mobile.

#### Scenario: Operator manages company gateway from Accounts
- **WHEN** a source administrator opens Accounts
- **THEN** source controls appear in the account list column and allow adding or editing a gateway and changing its enablement and preference

#### Scenario: Existing source is shared
- **WHEN** a source previously created in Settings is viewed in Accounts
- **THEN** the same source and settings are shown without importing a duplicate

#### Scenario: Restricted account administrator
- **WHEN** an account administrator lacks source write permission
- **THEN** the Accounts page does not expose the source administration section
