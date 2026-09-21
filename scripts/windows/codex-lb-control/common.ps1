Set-StrictMode -Version Latest

$script:ControllerDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

function Get-CodexLbControllerPaths {
    $repoRoot = [System.IO.Path]::GetFullPath((Join-Path $script:ControllerDirectory "..\..\.."))
    $localRoot = Join-Path $repoRoot ".local"
    $controllerState = Join-Path $localRoot "codex-lb-control"
    $runtimeRoot = Join-Path $localRoot "runtime"

    [PSCustomObject]@{
        RepoRoot = $repoRoot
        DataDirectory = Join-Path $repoRoot ".codex-lb"
        RuntimeRoot = $runtimeRoot
        PythonExecutable = Join-Path $runtimeRoot "Scripts\python.exe"
        ServiceLauncher = Join-Path $runtimeRoot "Scripts\codex-lb.exe"
        StateDirectory = $controllerState
        LogDirectory = Join-Path $controllerState "logs"
        PidFile = Join-Path $controllerState "codex-lb.pid"
        StdoutLog = Join-Path $controllerState "logs\codex-lb.out.log"
        StderrLog = Join-Path $controllerState "logs\codex-lb.err.log"
        DashboardUrl = "http://127.0.0.1:2455"
    }
}

function Initialize-CodexLbControllerDirectories {
    param([Parameter(Mandatory = $true)]$Paths)

    New-Item -ItemType Directory -Force -Path $Paths.DataDirectory, $Paths.StateDirectory, $Paths.LogDirectory | Out-Null
}

function Test-CodexLbDashboard {
    param([Parameter(Mandatory = $true)]$Paths)

    try {
        $response = Invoke-WebRequest -Uri ($Paths.DashboardUrl + "/") -UseBasicParsing -TimeoutSec 2
        return $response.StatusCode -eq 200 -and $response.Content -match "<title>Codex LB</title>"
    } catch {
        return $false
    }
}

function Test-CodexLbPort {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $connect = $client.ConnectAsync("127.0.0.1", 2455)
        if (-not $connect.Wait(750)) {
            return $false
        }
        return $client.Connected
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Get-SavedCodexLbPid {
    param([Parameter(Mandatory = $true)]$Paths)

    if (-not (Test-Path -LiteralPath $Paths.PidFile)) {
        return $null
    }

    $rawPid = (Get-Content -LiteralPath $Paths.PidFile -Raw).Trim()
    $savedPid = 0
    if (-not [int]::TryParse($rawPid, [ref]$savedPid) -or $savedPid -le 0) {
        throw "The controller PID file is invalid: $($Paths.PidFile)"
    }
    return $savedPid
}

function Get-OwnedCodexLbProcess {
    param([Parameter(Mandatory = $true)]$Paths)

    $savedPid = Get-SavedCodexLbPid -Paths $Paths
    if ($null -eq $savedPid) {
        return $null
    }

    $process = Get-Process -Id $savedPid -ErrorAction SilentlyContinue
    if ($null -eq $process) {
        return $null
    }

    $expectedPath = [System.IO.Path]::GetFullPath($Paths.PythonExecutable)
    $actualPath = if ($process.Path) { [System.IO.Path]::GetFullPath($process.Path) } else { "" }
    if ($actualPath -ine $expectedPath) {
        throw "PID $savedPid belongs to '$actualPath', not the managed Codex LB runtime. Refusing to manage it."
    }

    $processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $savedPid" -ErrorAction Stop
    $expectedCommand = '"' + $expectedPath + '" -m app.cli --host 127.0.0.1 --port 2455'
    if ($null -eq $processInfo -or $processInfo.CommandLine.Trim() -ine $expectedCommand) {
        throw "PID $savedPid is not the managed Codex LB command. Refusing to manage it."
    }

    return $process
}

function Assert-CodexLbControllerInstalled {
    param([Parameter(Mandatory = $true)]$Paths)

    if (-not (Test-Path -LiteralPath $Paths.PythonExecutable) -or -not (Test-Path -LiteralPath $Paths.ServiceLauncher)) {
        throw "The controller runtime is missing. Run scripts\windows\codex-lb-control\install.ps1 first."
    }
}
