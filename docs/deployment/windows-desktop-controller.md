# Windows desktop controller

If you cloned the repository on Windows, the repository includes a small desktop controller for the native packaged installation. It creates an isolated runtime with `uv`, a Desktop shortcut, and a control panel with Start, Stop, Status, and Open Dashboard buttons.

This is a local single-machine installation. It binds the service to `127.0.0.1:2455`; it is not a remote-access or Windows-Service setup. The controller uses the published `codex-lb` wheel so the dashboard assets are included even though the source checkout does not contain `app/static/`.

## Install after cloning

Install `uv` first if it is not already available. Then open PowerShell in the clone and run:

```powershell
cd "C:\path\to\codex-lb"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\windows\codex-lb-control\install.ps1"
```

The installer creates:

- `.local\runtime\` — the packaged Python runtime
- `.local\codex-lb-control\` — logs and PID state
- `.codex-lb\` — the SQLite database, encryption key, and account data
- `Codex LB Control.lnk` — a shortcut on the current user's Desktop

These paths are ignored by Git. Re-running the installer updates the runtime and shortcut but preserves `.codex-lb\` account data. Stop the service before re-installing so no running process is left on the old runtime.

To install a specific published version:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\windows\codex-lb-control\install.ps1" -Version 1.24.0
```

Use `-NoStart` when you only want to prepare the runtime and shortcut.

## Daily operation

Open **Codex LB Control** from the Desktop. Closing that window or the browser does not stop the background service.

The equivalent PowerShell commands are:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\windows\codex-lb-control\start.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\windows\codex-lb-control\status.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\windows\codex-lb-control\stop.ps1"
```

The dashboard is [http://127.0.0.1:2455](http://127.0.0.1:2455). Add each ChatGPT account from **Add account** in that dashboard; account state stays in `.codex-lb\` and is never committed.

The controller refuses to stop a PID unless both the executable path and the exact managed command line match. If port `2455` is occupied by another process, Start fails safely and leaves that process alone.

## Moving to another computer

Clone the repository again, install `uv`, and run the installer in the new clone. Do not copy `.codex-lb\` unless you deliberately want to migrate the encrypted account database and its encryption key together. A fresh clone is independent by design.

*Spec: [deployment-installation](https://github.com/Soju06/codex-lb/tree/main/openspec/specs/deployment-installation)*
