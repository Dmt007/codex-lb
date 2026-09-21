## Why

The documented native quick start (`uvx codex-lb`) gives Windows users a working server but no repository-owned way to manage it after the terminal closes. A local, ignored control script solves one checkout only: it disappears from every clone and cannot be shared safely through Git. Windows users who clone the repository need a repeatable installer that creates an isolated packaged runtime, a desktop shortcut, and explicit start/stop controls without committing account credentials or database files.

## What Changes

- Add a repository-owned Windows controller under `scripts/windows/codex-lb-control/` with install, start, stop, status, and WinForms control-panel scripts.
- Install the latest stable published `codex-lb` wheel into an ignored controller runtime instead of relying on an unbuilt source checkout.
- Keep runtime files, logs, PID state, encryption keys, and SQLite data in existing ignored directories inside the checkout.
- Create a desktop shortcut that opens the control panel with Start, Stop, Refresh Status, and Open Dashboard actions.
- Refuse to stop a PID unless it resolves to the controller's own executable, and bind the managed service to loopback only.
- Document the clone-to-install workflow and add platform-neutral artifact tests plus Windows smoke verification.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `deployment-installation`: add the clone-portable Windows desktop-controller installation path and its safety/portability contract.
- `user-documentation`: expose the Windows installation path from the quick start and published deployment documentation.

## Impact

- `scripts/windows/codex-lb-control/*.ps1`
- `tests/unit/test_windows_desktop_controller.py`
- `README.md`, `docs/getting-started.md`, `docs/deployment/windows-desktop-controller.md`, `mkdocs.yml`
- No application API, schema, database migration, frontend bundle, or environment-setting surface changes.
