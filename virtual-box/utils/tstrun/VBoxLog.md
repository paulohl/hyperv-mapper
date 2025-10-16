# What the logs say (in plain English markdown)

- __Core Isolation / Memory Integrity is ON__. VirtualBox is much less stable (or won’t start VMs) when Windows’ VBS/Memory Integrity is enabled unless it can fall back to WHP cleanly. Your VBoxUI.log shows: “Core Isolation (Memory Integrity): __ENABLED__”. (VBoxUI.log)
- __Hardening detects injected / altered sections__. VBoxHardening.log shows VirtualBox’s hardening layer restoring bytes and flagging differences in VBoxHeadless.exe sections and resources. That usually means a security/overlay/AV/driver is hooking the process (RGB/OC tools, audio enhancers, overlay apps, some AVs, etc.). When hardening is unhappy, VMs often go “aborted/unknown.” (VBoxHardening.log)

## Fixes to apply (once) for stability

1. __Decide your mode: “native VT-x” or “coexist with Hyper-V”__.    
      - __Fastest path to stability__: turn off Hyper-V stack + VBS.
           - Disable Core Isolation (Memory Integrity) in Windows Security → Device Security. Reboot.
           - Disable Hyper-V features (Hyper-V, Windows Hypervisor Platform, Virtual Machine Platform) via “Turn Windows features on or off”, then reboot.
           - bcdedit /set hypervisorlaunchtype off (admin cmd) and reboot.
      - __If you must keep Hyper-V/VBS__: keep Memory Integrity on, but know VirtualBox runs via WHP and can be less performant. Stick to recent VBox (you’re on 7.1.6, good) and avoid kernel-hooking tools.

2. __Remove/neutralize hooky software__.    
Typical culprits: AV real-time DLL injection, motherboard/RGB utilities, audio enhancements (Nahimic/Sonic Studio), screen recorders/overlays, HUDs, “helper” updaters. Add __exclusions__ for the VBox binaries folder or temporarily stop them to test. The hardening “Differences in section … Restored … original file content” is a giveaway here. (VBoxHardening.log)

3. __Extension Pack match__.    
Make sure the __Extension Pack version exactly matches__ your VirtualBox version.

## Add reliable “checkpoints” & logs when a VM misbehaves

Below are drop-in steps + a tiny __watchdog__ that will 1) snapshot on each start, 2) log state changes, 3) collect VBox logs on failure, and 4) auto-restart a crashed/unknown VM. Everything is file-based so you can ship it to your GitHub “troubleshooting” folder.    


### A) Turn on per-VM serial console to a file (super helpful)    

VBoxManage modifyvm "<VM_NAME>" --uart1 0x3F8 4    
VBoxManage modifyvm "<VM_NAME>" --uartmode1 file "C:\VBoxLogs\<VM_NAME>\serial.log"
- Many guests (esp. Linux, but Windows too with proper boot flags) will dump useful early-boot messages here even when the UI is frozen.    

### B) Keep a rolling copy of VBox logs each run    
VirtualBox already writes VBox.log, VBox.log.1… in the VM’s folder. We’ll copy them to a timestamped crash bundle whenever the VM isn’t “running”.     

$$$ C) Auto-snapshot on every clean start (optional but great for repros)     
VBoxManage snapshot "<VM_NAME>" take "prestart-%DATE%-%TIME%" --live      



(If you prefer weekly/daily snapshots, we can trim old ones.)

D) Lightweight Watchdog (PowerShell)

Save as utils\watchdog.ps1:

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

E) Schedule it every 1–2 minutes

Create a Scheduled Task (as you did for your other labs) to run:

Program/script: powershell.exe
Arguments: -NoProfile -ExecutionPolicy Bypass -File "C:\users\paulo\documents\dev\hyperv-mapper\utils\watchdog.ps1" -VmName "<VM_NAME>" -LogRoot "C:\VBoxLogs"


Set Run whether user is logged on or not, and Run with highest privileges.

Now each time the VM slips into aborted/unknown, you get a timestamped bundle:

C:\VBoxLogs\<VM_NAME>\20251015-184958\
    state.txt
    VBox.log / VBox.log.1 ...
    System.evtx / Application.evtx
    startvm.txt


Perfect for your “troubleshooting” repo.

Extra tips you’ll appreciate

Detect hardening failures instantly: if VBoxManage startvm fails but the GUI shows nothing, immediately open the latest VBoxHardening.log in the VM’s folder—those “Differences in section … Restored …” lines are smoking guns for DLL injection. 

VBoxHardening

When GA flaps a lot (“GA state really changed / doesn’t really changed” spam in VBoxUI.log), that’s typically additions/tools failing to initialize cleanly—often correlated with VBS/Hyper-V mode. 

VBoxUI

If you must keep Hyper-V: try to keep the host lean (no overlays), stick to pure NIC types (virtio isn’t in VBox; use Intel PRO/1000 or paravirt where appropriate), and avoid host-USB filters that hook constantly.
