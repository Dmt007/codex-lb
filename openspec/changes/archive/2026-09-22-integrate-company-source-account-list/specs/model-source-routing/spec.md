## ADDED Requirements

### Requirement: Gateway cards share the account list and add chooser

For source administrators, gateway cards SHALL appear inside the same scrolling list as subscription account cards, not in a separate panel below the list. Add account SHALL offer a company gateway option opening the existing source creation form. Source editing, enablement and preference SHALL remain available on the gateway cards. Settings SHALL continue using the same stored sources. Restricted operators SHALL NOT receive source administration controls.

#### Scenario: Gateway in account card list
- **WHEN** a source administrator opens Accounts with a saved gateway
- **THEN** its card is inside the account list scroll region with its existing source controls

#### Scenario: Add company gateway
- **WHEN** the administrator chooses Company gateway in Add account
- **THEN** the chooser closes and the source creation dialog opens
