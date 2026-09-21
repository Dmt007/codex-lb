$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "common.ps1")

$paths = Get-CodexLbControllerPaths
Assert-CodexLbControllerInstalled -Paths $paths
Initialize-CodexLbControllerDirectories -Paths $paths

$ownedProcess = $null
try {
    $ownedProcess = Get-OwnedCodexLbProcess -Paths $paths
} catch {
    throw $_
}

if ($null -ne $ownedProcess) {
    if (Test-CodexLbDashboard -Paths $paths) {
        Write-Output "codex-lb is already running (PID $($ownedProcess.Id))."
        Write-Output "Dashboard: $($paths.DashboardUrl)"
        return
    }
    throw "The managed process exists (PID $($ownedProcess.Id)) but the dashboard is unhealthy. Stop it before restarting."
}

if (Test-Path -LiteralPath $paths.PidFile) {
    Remove-Item -LiteralPath $paths.PidFile -Force
}

if (Test-CodexLbPort) {
    throw "Port 2455 is already in use by an unmanaged process. Stop that process or change its port before starting Codex LB."
}

$env:CODEX_LB_DATA_DIR = $paths.DataDirectory
$process = Start-Process `
    -FilePath $paths.PythonExecutable `
    -ArgumentList @("-m", "app.cli", "--host", "127.0.0.1", "--port", "2455") `
    -WorkingDirectory $paths.RepoRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $paths.StdoutLog `
    -RedirectStandardError $paths.StderrLog `
    -PassThru

Set-Content -LiteralPath $paths.PidFile -Value $process.Id

$ready = $false
for ($attempt = 0; $attempt -lt 60; $attempt++) {
    if ($process.HasExited) {
        break
    }
    if (Test-CodexLbDashboard -Paths $paths) {
        $ready = $true
        break
    }
    Start-Sleep -Milliseconds 500
}

if (-not $ready) {
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -ErrorAction SilentlyContinue
        [void]$process.WaitForExit(10000)
    }
    Remove-Item -LiteralPath $paths.PidFile -Force -ErrorAction SilentlyContinue
    $details = if (Test-Path -LiteralPath $paths.StderrLog) {
        (Get-Content -LiteralPath $paths.StderrLog -Tail 30) -join [Environment]::NewLine
    } else {
        "No error log was created."
    }
    throw "codex-lb failed to start.`n$details"
}

Write-Output "codex-lb started (PID $($process.Id))."
Write-Output "Dashboard: $($paths.DashboardUrl)"
Write-Output "Data: $($paths.DataDirectory)"
Write-Output "Logs: $($paths.LogDirectory)"
