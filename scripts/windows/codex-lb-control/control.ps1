$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

$startScript = Join-Path $PSScriptRoot "start.ps1"
$stopScript = Join-Path $PSScriptRoot "stop.ps1"
$statusScript = Join-Path $PSScriptRoot "status.ps1"
$dashboardUrl = "http://127.0.0.1:2455"

function Get-CodexLbStatus {
    return ((& $statusScript 2>&1 | Out-String).Trim())
}

function Update-StatusLabel {
    $status = Get-CodexLbStatus
    if ($status -like "RUNNING*") {
        $statusLabel.Text = "Status: RUNNING"
        $statusLabel.ForeColor = [System.Drawing.Color]::ForestGreen
    } elseif ($status -like "UNHEALTHY*") {
        $statusLabel.Text = "Status: UNHEALTHY"
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    } elseif ($status -like "STOPPED") {
        $statusLabel.Text = "Status: STOPPED"
        $statusLabel.ForeColor = [System.Drawing.Color]::Firebrick
    } else {
        $statusLabel.Text = "Status: $status"
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    }
}

function Show-ControllerResult {
    param(
        [Parameter(Mandatory = $true)][string]$Title,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    $form.UseWaitCursor = $true
    try {
        $result = (& $Action 2>&1 | Out-String).Trim()
        [System.Windows.Forms.MessageBox]::Show($result, $Title, "OK", "Information") | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "$Title failed", "OK", "Error") | Out-Null
    } finally {
        $form.UseWaitCursor = $false
        Update-StatusLabel
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Codex LB Control"
$form.StartPosition = "CenterScreen"
$form.ClientSize = New-Object System.Drawing.Size(390, 245)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $true

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Codex LB Local Service"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 15, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(77, 20)
$form.Controls.Add($titleLabel)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Status: checking..."
$statusLabel.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$statusLabel.AutoSize = $true
$statusLabel.Location = New-Object System.Drawing.Point(105, 62)
$form.Controls.Add($statusLabel)

$startButton = New-Object System.Windows.Forms.Button
$startButton.Text = "START"
$startButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$startButton.Size = New-Object System.Drawing.Size(145, 42)
$startButton.Location = New-Object System.Drawing.Point(43, 103)
$startButton.BackColor = [System.Drawing.Color]::Honeydew
$startButton.Add_Click({ Show-ControllerResult -Title "Codex LB" -Action { & $startScript } })
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Text = "STOP"
$stopButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$stopButton.Size = New-Object System.Drawing.Size(145, 42)
$stopButton.Location = New-Object System.Drawing.Point(202, 103)
$stopButton.BackColor = [System.Drawing.Color]::MistyRose
$stopButton.Add_Click({ Show-ControllerResult -Title "Codex LB" -Action { & $stopScript } })
$form.Controls.Add($stopButton)

$statusButton = New-Object System.Windows.Forms.Button
$statusButton.Text = "REFRESH STATUS"
$statusButton.Size = New-Object System.Drawing.Size(145, 34)
$statusButton.Location = New-Object System.Drawing.Point(43, 160)
$statusButton.Add_Click({ Update-StatusLabel })
$form.Controls.Add($statusButton)

$dashboardButton = New-Object System.Windows.Forms.Button
$dashboardButton.Text = "OPEN DASHBOARD"
$dashboardButton.Size = New-Object System.Drawing.Size(145, 34)
$dashboardButton.Location = New-Object System.Drawing.Point(202, 160)
$dashboardButton.Add_Click({ Start-Process $dashboardUrl })
$form.Controls.Add($dashboardButton)

$hintLabel = New-Object System.Windows.Forms.Label
$hintLabel.Text = "Dashboard: http://127.0.0.1:2455"
$hintLabel.ForeColor = [System.Drawing.Color]::DimGray
$hintLabel.AutoSize = $true
$hintLabel.Location = New-Object System.Drawing.Point(85, 211)
$form.Controls.Add($hintLabel)

$form.Add_Shown({ Update-StatusLabel })
[void]$form.ShowDialog()
