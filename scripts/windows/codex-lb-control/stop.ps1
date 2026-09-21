$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$paths = Get-CodexLbControllerPaths
$process = Get-OwnedCodexLbProcess -Paths $paths

if ($null -eq $process) {
    Remove-Item -LiteralPath $paths.PidFile -Force -ErrorAction SilentlyContinue
    Write-Output "codex-lb is not running."
    return
}

Stop-Process -Id $process.Id
[void]$process.WaitForExit(10000)
Remove-Item -LiteralPath $paths.PidFile -Force -ErrorAction SilentlyContinue
Write-Output "codex-lb stopped (PID $($process.Id))."
