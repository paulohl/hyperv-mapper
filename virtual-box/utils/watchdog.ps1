
<#
.SYNOPSIS
  VirtualBox VM watchdog and self-healer

.DESCRIPTION
  Monitors a specific VirtualBox VM, logs its state, collects diagnostic data
  when the VM crashes or enters "aborted"/"unknown" state, and restarts it.
  Creates timestamped folders under C:\VBoxLogs\<VM_NAME>\ for every incident.

.PARAMETER VmName
  The exact name of the VM as shown in VBoxManage list vms.

.PARAMETER LogRoot
  Base path for log collection (default: C:\VBoxLogs)

.EXAMPLE
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File utils\watchdog.ps1 -VmName "WinDev2407Eval"
#>

param(
  [Parameter(Mandatory=$true)][string]$VmName,
  [string]$LogRoot = "C:\VBoxLogs"
)

$ErrorActionPreference = "Stop"
$stamp  = (Get-Date).ToString("yyyyMMdd-HHmmss")
$vmDir  = Join-Path $LogRoot $VmName
$runDir = Join-Path $vmDir $stamp
New-Item -ItemType Directory -Force -Path $runDir | Out-Null

function Write-Log {
  param([string]$msg)
  $line = "[$(Get-Date -Format 'u')] $msg"
  Write-Output $line
  $line | Tee-Object -FilePath (Join-Path $vmDir "watchdog.log") -Append | Out-Null
}

function Get-VMState {
  param([string]$name)
  $info = & VBoxManage showvminfo $name --machinereadable 2>$null
  if ($LASTEXITCODE -ne 0) { return "unknown" }
  foreach ($line in $info) {
    if ($line -like "VMState=*") {
      return ($line -split "=")[1].Trim('"')
    }
  }
  return "unknown"
}

Write-Log "---- Watchdog invoked for $VmName ----"
$state = Get-VMState $VmName
Write-Log "Current state: $state"

# Healthy case
if ($state -eq "running" -or $state -eq "paused") {
  Write-Log "$VmName is healthy; no action taken."
  exit 0
}

# Problematic case
Write-Log "$VmName appears to be in bad state: $state"
Write-Log "Collecting diagnostics..."

# Get VM home folder
$cfg = & VBoxManage showvminfo $VmName --machinereadable 2>$null
$vmHome = ($cfg | Where-Object { $_ -like "CfgFile=*"} | ForEach-Object { ($_ -split "=")[1].Trim('"') })
if ($vmHome) {
  $vmHomeDir = Split-Path $vmHome -Parent
  Get-ChildItem $vmHomeDir -Filter "VBox*.log*" -ErrorAction SilentlyContinue | `
    Copy-Item -Destination $runDir -ErrorAction SilentlyContinue
}

# Export last hour of Windows logs
try {
  wevtutil epl System      (Join-Path $runDir "System.evtx")      /q:"*[System[TimeCreated[timediff(@SystemTime) <= 3600000]]]"
  wevtutil epl Application (Join-Path $runDir "Application.evtx") /q:"*[System[TimeCreated[timediff(@SystemTime) <= 3600000]]]"
} catch { Write-Log "Event export failed: $_" }

# Take a recovery snapshot
try {
  & VBoxManage snapshot $VmName take "watchdog-$stamp" --live | Out-Null
  Write-Log "Snapshot watchdog-$stamp created."
} catch {
  Write-Log "Snapshot failed: $_"
}

# Attempt restart
Write-Log "Attempting restart..."
try {
  $out = & VBoxManage startvm $VmName --type headless 2>&1
  $out | Out-File -Encoding utf8 (Join-Path $runDir "startvm.txt")
  Start-Sleep 5
  $state2 = Get-VMState $VmName
  Write-Log "Post-restart state: $state2"
} catch {
  Write-Log "Restart command failed: $_"
}

Write-Log "---- Watchdog cycle complete ----`n"
