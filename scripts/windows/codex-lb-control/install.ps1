[CmdletBinding()]
param(
    [switch]$NoStart,
    [ValidatePattern("^[0-9A-Za-z][0-9A-Za-z._+-]*$")]
    [string]$Version
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$paths = Get-CodexLbControllerPaths
$uv = Get-Command uv -ErrorAction SilentlyContinue
if ($null -eq $uv) {
    throw "uv is required. Install it from https://docs.astral.sh/uv/getting-started/installation/ and run this installer again."
}

Initialize-CodexLbControllerDirectories -Paths $paths
$runningProcess = Get-OwnedCodexLbProcess -Paths $paths
if ($null -ne $runningProcess) {
    throw "Codex LB is running (PID $($runningProcess.Id)). Stop it before reinstalling the runtime. Account data will be preserved."
}

if (-not (Test-Path -LiteralPath $paths.PythonExecutable)) {
    & $uv.Source venv $paths.RuntimeRoot --python 3.13
    if ($LASTEXITCODE -ne 0) {
        throw "uv could not create the controller runtime."
    }
}

$packageSpec = if ($Version) { "codex-lb==$Version" } else { "codex-lb" }
& $uv.Source pip install --python $paths.PythonExecutable --upgrade $packageSpec
if ($LASTEXITCODE -ne 0) {
    throw "uv could not install $packageSpec."
}

Assert-CodexLbControllerInstalled -Paths $paths

$desktop = [Environment]::GetFolderPath("Desktop")
if (-not [System.IO.Path]::IsPathRooted($desktop)) {
    throw "Windows did not return an absolute Desktop path."
}

$powershellExe = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
if (-not (Test-Path -LiteralPath $powershellExe)) {
    $powershellExe = (Get-Command powershell.exe -ErrorAction Stop).Source
}

$controlScript = Join-Path $PSScriptRoot "control.ps1"
$shortcutPath = Join-Path ([System.IO.Path]::GetFullPath($desktop)) "Codex LB Control.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $powershellExe
$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "' + $controlScript + '"'
$shortcut.WorkingDirectory = $paths.RepoRoot
$shortcut.IconLocation = $paths.ServiceLauncher + ",0"
$shortcut.Description = "Start, stop, and open the local Codex LB service"
$shortcut.WindowStyle = 7
$shortcut.Save()

Write-Output "Codex LB controller installed."
Write-Output "Shortcut: $shortcutPath"
Write-Output "Data: $($paths.DataDirectory)"

if (-not $NoStart) {
    & (Join-Path $PSScriptRoot "start.ps1")
}
