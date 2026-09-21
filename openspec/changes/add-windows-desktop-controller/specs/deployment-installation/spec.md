## ADDED Requirements

### Requirement: Windows desktop controller is clone-portable and local by default

The repository SHALL provide a Windows PowerShell installer and desktop control panel for a native packaged `codex-lb` runtime. From any writable clone, the installer MUST create or update an isolated ignored runtime, create a desktop shortcut targeting the tracked control panel in that clone, and preserve existing account data on re-install. The managed service MUST bind only to `127.0.0.1:2455`, MUST store its database, encryption key, logs, and PID state only in Git-ignored paths, and MUST continue running when the control panel or browser closes.

The controller MUST launch the installed module in the runtime Python process rather than track a short-lived console-script launcher. It MUST treat a saved PID as untrusted: status and stop MUST verify that the live PID's executable is the controller runtime's Python executable and its command line is the managed server invocation before treating it as owned or terminating it. Start MUST be idempotent for an already-running owned process and MUST fail without terminating anything when the port is occupied by an unowned process. Re-install MUST refuse to update a running managed runtime. The installer MUST fail with an actionable prerequisite message when `uv` is unavailable and MUST NOT install system software or weaken the machine execution policy persistently.

#### Scenario: Fresh clone installs a usable desktop controller

- **GIVEN** a writable Windows clone with `uv` available
- **WHEN** the user runs the repository's controller installer
- **THEN** an isolated packaged runtime and desktop shortcut are created
- **AND** the dashboard becomes reachable at `http://127.0.0.1:2455`
- **AND** no runtime, log, PID, database, encryption-key, or account file becomes tracked by Git

#### Scenario: Re-install preserves account data

- **GIVEN** the clone already contains controller-managed account data
- **WHEN** the installer is run again
- **THEN** the packaged runtime and desktop shortcut are refreshed
- **AND** the account database and encryption key are not removed or replaced

#### Scenario: Control window is not process ownership

- **GIVEN** the controller started the managed service
- **WHEN** the control panel or browser is closed
- **THEN** the managed service remains running
- **AND** only the Stop action terminates it

#### Scenario: Stale or foreign PID fails safe

- **GIVEN** the PID file names no process or a process whose executable is not the controller runtime executable
- **WHEN** status or stop is requested
- **THEN** status does not report that process as managed
- **AND** stop does not terminate the mismatched process

#### Scenario: Port is already owned elsewhere

- **GIVEN** an unowned process is listening on port 2455
- **WHEN** Start is requested
- **THEN** startup fails with an actionable error
- **AND** the existing process is not terminated

#### Scenario: Missing uv is reported without machine mutation

- **GIVEN** `uv` is not available on `PATH`
- **WHEN** the installer runs
- **THEN** installation stops with instructions for installing `uv`
- **AND** no system package manager or persistent execution-policy setting is invoked
