## Context

The source checkout intentionally excludes `app/static/`, so running the editable backend directly does not provide the release dashboard unless the frontend toolchain builds it. The published wheel already contains the dashboard and is the supported native `uvx` path. The existing machine-local controller proved the desired interaction, but it lives below `.local/` and therefore cannot survive a fresh clone.

## Goals / Non-Goals

**Goals**

- One PowerShell install command from a Windows clone creates a usable controller and desktop shortcut.
- Start and stop are deterministic, safe against stale/reused PIDs, and do not require an open terminal.
- A fresh clone gets fresh local data; secrets and account state never enter Git.
- Development `.venv` remains independent from the packaged controller runtime.

**Non-Goals**

- macOS/Linux GUI launchers.
- Installing Git or `uv` automatically.
- Copying account data between machines.
- Running at Windows sign-in or as a Windows Service.
- Replacing Docker, `uvx`, Nix, or the development workflow.

## Decisions

### Use a packaged runtime separate from development

`install.ps1` creates `.local/runtime` and installs the latest stable `codex-lb` wheel there with `uv pip install --upgrade`. This reuses the release artifact containing the compiled dashboard and does not mutate the repository's development `.venv`. An optional version argument permits a reproducible reinstall when an operator needs one.

### Keep data checkout-local but ignored

The controller sets `CODEX_LB_DATA_DIR` to `<repo>/.codex-lb`. The existing `.gitignore` excludes both `.codex-lb/` and `.local/`, so the database, encryption key, logs, runtime, and PID file stay off Git. Another clone starts with independent data while a re-install in the same clone preserves its accounts.

### Treat process ownership as a safety boundary

The PID file alone is not trusted. The controller launches the installed module directly as `.local/runtime/Scripts/python.exe -m app.cli`, so the captured PID is the long-lived server rather than the short-lived Windows console-script launcher. Status and stop resolve the saved PID and compare the process executable path with that exact runtime Python executable. A missing process becomes stopped; a live mismatched process is refused rather than terminated. Start rejects an occupied dashboard port that is not already the managed process.

### Keep network exposure explicit

The controller always starts `codex-lb --host 127.0.0.1 --port 2455`. Remote exposure remains a separate documented deployment decision. Closing the controller window or browser does not stop the background process.

### Desktop shortcut points at tracked code

The installer creates `Codex LB Control.lnk` on the current user's desktop. Its target is Windows PowerShell with `-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden`, and its script path is the tracked `control.ps1` in that clone. Re-running the installer idempotently refreshes both runtime and shortcut.

## Risks / Trade-offs

- A moved or deleted checkout invalidates its shortcut. Re-running `install.ps1` in the new location repairs it.
- Installation requires `uv` and network access to the Python package index. The installer fails with one actionable prerequisite message when `uv` is absent.
- The latest stable wheel can lag repository `main`. This is intentional: the controller is an operator path, while the source checkout remains a development path. `-Version` can pin a published release.
- Windows PowerShell script policy can block direct execution. The documented command and generated shortcut use process-scoped `ExecutionPolicy Bypass`; they do not change machine policy.

## Verification

- Parse every PowerShell file with the Windows PowerShell parser.
- Run `install.ps1 -NoStart`, inspect the isolated runtime and shortcut, then exercise stop/start/status against the loopback dashboard.
- Run cross-platform pytest artifact tests that enforce ignored state paths, loopback binding, safe executable ownership checks, and docs/spec presence.
- Run strict OpenSpec validation and the relevant documentation checks when their tools are available.
