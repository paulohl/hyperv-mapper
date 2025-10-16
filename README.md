# 🧩 VirtualBox Watchdog Subsystem       

The VirtualBox Watchdog is an optional utility designed for developers running nested virtualization or unstable VM environments (e.g., Windows + Hyper-V + VirtualBox mixed labs).
It monitors a given VM, logs its state transitions, captures forensic data when it crashes, and can automatically restart it.

## ⚙️ Components      

| **File**                         | **Purpose**                                                                                                   |
|:---------------------------------|:--------------------------------------------------------------------------------------------------------------|
|utils/watchdog.ps1	               | Main watchdog script — logs, collects VBox + Windows event data, restarts VMs in “Aborted” or “Unknown” state |
|utils/install-watchdog-task.ps1	 | Installs the watchdog as a Windows Scheduled Task (runs even when logged out)                                 |
|docs/VirtualBox-Unknown-State.md	 | Detailed explanation of the “Aborted” / “Unknown” states, root causes, and recovery guidance                  |       

## 🧭 Quick Start       

**Step 1**: Test manually         
```cmd
powershell.exe -ExecutionPolicy Bypass -File utils\watchdog.ps1 -VmName "WinDev2407Eval"

```

**Step 2**: Install as automatic task          
```cmd
powershell.exe -ExecutionPolicy Bypass -File utils\install-watchdog-task.ps1 -VmName "WinDev2407Eval"

```

**Step 3**: Verify         
```cmd
Get-ScheduledTask | Where-Object TaskName -like "*VBox Watchdog*"

```

Once active, the watchdog:        
- Runs every 2 minutes (configurable)
- Archives crash logs under C:\VBoxLogs\<VM_NAME>\<timestamp>\
- Restarts the VM automatically         

## 📁 Folder Layout       
C:\VBoxLogs\WinDev2407Eval\      
├─ watchdog.log     
├─ 2025-10-16-164931\     
│  ├─ VBox.log      
│  ├─ System.evtx      
│  ├─ Application.evtx     
│  ├─ startvm.txt     
│  └─ snapshot.txt      

## 🧠 Why It Matters

VirtualBox VMs can enter Unknown or Aborted states silently, especially on Windows 11 hosts with Core Isolation or Hyper-V enabled.
This utility ensures stability, forensic traceability, and fully unattended recovery.

### 🔐 Notes

- Tested on Windows 10/11 hosts with VirtualBox ≥ 7.0.14
- Requires VBoxManage.exe in PATH
- Logs are stored locally, no remote uploads
- Safe to schedule as SYSTEM; no network credentials needed


_____________
_____________
_____________
_____________


hyperv-mapper/      
<br>
├─ docs/     
│  ├─ HVMAPPER.md      
│  ├─ README.md       
├─ guest/       
│  ├─ set_rdp_port.ps1       
│  ├─ setup-rdp.ps1      
│  ├─ README.md       
│  ├─ ...          
├─ host/       
│  ├─ create_nat.ps1      
│  ├─ map_guest_port.ps1      
│  ├─ setup-nat.ps1      
│  ├─ README.md      
│  └─ ...      
├─ tst-run/      
│  ├─ PRETST.md      
│  ├─ TShoot-01.md     
│  ├─ README.md      
│  └─ ...      
├─ utils/         
│  ├─ cleanup-duplicates.ps1           
│  ├─ status.ps1      
│  ├─ test_connectivity.ps1      
│  ├─ README.md      
│  └─ ...     
├─ virtual-box/      
│  ├─ docs/     
│  │  ├─ VirtualBox-Unknown-State.md       
│  │  ├─ TS01.md      
│  │  ├─ TS02.md      
│  │  ├─ problem_finder.xml      
│  │  ├─ verify-problematic-values.xml       
│  │  └─ ...      
│  ├─ utils/      
│  │  ├─ install-watchdog-task.ps1      
│  │  ├─ watchdog.ps1      
│  │  ├─ tstrun/       
│  │  │  ├─ VBox.log     
│  │  │  ├─ VBoxHardening.log       
│  │  │  ├─ VBoxLog.md      
│  │  │  ├─ VBoxUI.log      
│  │  │  └─ ...      
│  │  ├─ README.md      
│  │  └─ ...      
├─ README.md        
└─ .gitignore     
