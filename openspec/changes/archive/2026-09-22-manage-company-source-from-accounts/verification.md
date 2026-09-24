# Verification

Accounts and Settings share source controls, dialogs and query keys. The Accounts
column uses a compact layout. Source administration follows the same canWrite
permission as Settings and the backend write gate.

TypeScript passes. Accounts page and model-source suites: 29 tests passed,
including placement and restricted-permission cases. Chrome verified Add source
opens the dialog, preference updates and narrow-screen horizontal bounds.
Desktop/mobile screenshots are attached; before.png shows the previous account
column with the new source section hidden for comparison. Screenshots use mocked
API data, not live company credentials. No live source was registered.
