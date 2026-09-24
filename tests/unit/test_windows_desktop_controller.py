from pathlib import Path

REPOSITORY_ROOT = Path(__file__).parents[2]
CONTROLLER_ROOT = REPOSITORY_ROOT / "scripts" / "windows" / "codex-lb-control"


def test_windows_controller_scripts_are_tracked_artifacts() -> None:
    expected = {"common.ps1", "control.ps1", "install.ps1", "start.ps1", "status.ps1", "stop.ps1"}
    assert {path.name for path in CONTROLLER_ROOT.glob("*.ps1")} == expected


def test_windows_controller_is_local_and_uses_packaged_runtime() -> None:
    common = (CONTROLLER_ROOT / "common.ps1").read_text(encoding="utf-8-sig")
    start = (CONTROLLER_ROOT / "start.ps1").read_text(encoding="utf-8-sig")
    assert 'DashboardUrl = "http://127.0.0.1:2455"' in common
    assert '"-m", "app.cli", "--host", "127.0.0.1", "--port", "2455"' in start
    assert "ServiceLauncher" in common
    assert "CODEX_LB_DATA_DIR" in start


def test_windows_controller_refuses_foreign_processes() -> None:
    common = (CONTROLLER_ROOT / "common.ps1").read_text(encoding="utf-8-sig")
    assert "Get-CimInstance Win32_Process" in common
    assert "Refusing to manage it" in common
    assert "Re-install" not in common


def test_windows_controller_documentation_links_spec() -> None:
    docs = (REPOSITORY_ROOT / "docs" / "deployment" / "windows-desktop-controller.md").read_text(encoding="utf-8")
    assert "openspec/specs/deployment-installation" in docs
    assert "install.ps1" in docs
    assert "stop.ps1" in docs
