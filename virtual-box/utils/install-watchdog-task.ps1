# What this script does
#
# - Automatically registers the watchdog as a SYSTEM-level scheduled task, so it runs even if you’re logged out.
# - Cleans up any old instance with the same name.
# - Runs every 2 minutes by default (configurable).
# - Ensures parallel execution (so one delayed run doesn’t block another).
# - Includes clear output confirming everything succeeded.
#
<#
.SYNOPSIS
  One-click installer for the VirtualBox watchdog scheduled task.

.DESCRIPTION
  Registers a Windows Scheduled Task that runs the watchdog every few minutes
  to monitor and automatically recover a chosen VirtualBox VM.

.PARAMETER VmName
  Name of the VirtualBox VM to monitor.

.PARAMETER ScriptPath
  Full path to watchdog.ps1 (default assumes repo layout).

.PARAMETER IntervalMinutes
  How often to poll the VM (default 2 minutes).

.EXAMPLE
  powershell.exe -ExecutionPolicy Bypass -File utils\install-watchdog-task.ps1 -VmName "WinDev2407Eval"
#>

param(
  [Parameter(Mandatory=$true)][string]$VmName,
  [string]$ScriptPath = "C:\users\paulo\documents\dev\hyperv-mapper\utils\watchdog.ps1",
  [int]$IntervalMinutes = 2
)

$ErrorActionPreference = "Stop"
$taskName = "VBox Watchdog - $VmName"

# Clean up any previous task
try {
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
  Write-Host "Removed any existing task: $taskName"
} catch {}

# Construct the PowerShell command
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`" -VmName `"$VmName`""

# Trigger every N minutes indefinitely
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration ([TimeSpan]::MaxValue)

# Run with highest privileges, even when user not logged in
$principal = New-ScheduledTaskPrincipal -UserId "NT AUTHORITY\SYSTEM" -RunLevel Highest

# Description and metadata
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances Parallel

# Register task
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings `
  -Description "Monitors $VmName, collects logs, and restarts automatically if in aborted/unknown state."

Write-Host "✅ Task '$taskName' installed successfully!"
Write-Host "   Interval: every $IntervalMinutes minute(s)"
Write-Host "   Script:   $ScriptPath"
Write-Host "   VM:       $VmName"
Write-Host "----------------------------------------"
Write-Host "To verify:"
Write-Host "  Get-ScheduledTask -TaskName '$taskName' | fl *"
