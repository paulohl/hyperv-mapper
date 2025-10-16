param(
  [Parameter(Mandatory=$true)][string]$VmName,
  [string]$LogRoot = "C:\VBoxLogs"
)
$ErrorActionPreference = "Stop"
$stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$vmDir = Join-Path $LogRoot $VmName
$runDir = Join-Path $vmDir $stamp
New-Item -ItemType Directory -Force -Path $runDir | Out-Null
# Helper: grab VM state quickly
function Get-VMState($name){
  $info = & VBoxManage showvminfo $name --machinereadable 2>&1
  if ($LASTEXITCODE -ne 0) { return "unknown" }
  foreach($line in $info){
    if ($line -like "VMState=*"){
      return ($line -split "=")[1].Trim('"')
    }
  }
  return "unknown"
}
$state = Get-VMState $VmName
$state | Out-File -Encoding utf8 (Join-Path $runDir "state.txt")
if ($state -eq "running") {
  # VM is healthy; do nothing extra.
  Write-Output "[$stamp] $VmName is running." | Tee-Object -FilePath (Join-Path $vmDir "watchdog.log") -Append
  exit 0
}
# VM not running: collect logs and try recovery
Write-Output "[$stamp] $VmName state=$state; collecting logs and restarting..." | Tee-Object -FilePath (Join-Path $vmDir "watchdog.log") -Append
# Copy VBox logs from the VM home folder
# Get VM home dir
$show = & VBoxManage showvminfo $VmName --machinereadable
$vmHome = ($show | Where-Object {$_ -like "CfgFile=*"} | ForEach-Object { ($_ -split "=")[1].Trim('"') })
if ($vmHome) {
  $vmHomeDir = Split-Path $vmHome -Parent
  Get-ChildItem $vmHomeDir -Filter "VBox*.log*" -ErrorAction SilentlyContinue | `
    Copy-Item -Destination $runDir -ErrorAction SilentlyContinue
}
# Windows event summary (System & Application last 200)
wevtutil epl System       (Join-Path $runDir "System.evtx") /q:"*[System[TimeCreated[timediff(@SystemTime) <= 3600000]]]"
wevtutil epl Application  (Join-Path $runDir "Application.evtx") /q:"*[System[TimeCreated[timediff(@SystemTime) <= 3600000]]]"
# Optional: take a pre-start snapshot (comment out if you don’t want snapshot spam)
try { & VBoxManage snapshot $VmName take "watchdog-$stamp" --live | Out-Null } catch {}

# Try to start headless and log result
$start = & VBoxManage startvm $VmName --type headless 2>&1
$start | Out-File -Encoding utf8 (Join-Path $runDir "startvm.txt")
# Re-check state
Start-Sleep 5
$state2 = Get-VMState $VmName
"[$stamp] restart state=$state2" | Tee-Object -FilePath (Join-Path $vmDir "watchdog.log") -Append
exit 0
