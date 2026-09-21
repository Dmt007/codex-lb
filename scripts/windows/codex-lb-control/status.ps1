$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$paths = Get-CodexLbControllerPaths

try {
    $process = Get-OwnedCodexLbProcess -Paths $paths
} catch {
    Write-Output ("UNMANAGED PID FILE - " + $_.Exception.Message)
    return
}

if ($null -ne $process) {
    if (Test-CodexLbDashboard -Paths $paths) {
        Write-Output "RUNNING - PID $($process.Id) - $($paths.DashboardUrl)"
    } else {
        Write-Output "UNHEALTHY - PID $($process.Id)"
    }
    return
}

if (Test-Path -LiteralPath $paths.PidFile) {
    Remove-Item -LiteralPath $paths.PidFile -Force -ErrorAction SilentlyContinue
}

if (Test-CodexLbPort) {
    Write-Output "PORT 2455 IN USE - UNMANAGED"
} else {
    Write-Output "STOPPED"
}
