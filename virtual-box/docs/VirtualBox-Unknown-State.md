# 🧠 Understanding “Unknown” or “Aborted” States in VirtualBox

When a VM in VirtualBox stops responding and shows *Aborted* or *Unknown*, it usually means the **hypervisor process crashed, was terminated by Windows, or failed hardening checks**. The GUI doesn’t always surface a clear reason.

---

## 🔍 Common Root Causes

| Category | Typical Symptoms | Fix |
|-----------|-----------------|-----|
| **Hyper-V / Memory Integrity (VBS)** | VBoxUI.log shows `Core Isolation (Memory Integrity): ENABLED` and CPU fallback to WHP / “Snail mode” | Disable **Memory Integrity** in *Windows Security → Device Security*; or disable Hyper-V (`bcdedit /set hypervisorlaunchtype off`) |
| **DLL injection / driver hooks** | VBoxHardening.log shows “Differences in section … Restored …” | Stop or uninstall overlay tools (RGB, Nahimic, Sonic Studio, antivirus DLL hooks) |
| **Extension pack mismatch** | USB or network devices missing | Install the exact matching **Extension Pack** |
| **Sleep / hibernate events** | VM aborts after laptop sleep | Disable host sleep or use the watchdog to auto-recover |
| **Old logs filling disk** | VBoxManage can’t write to `Logs\` | Clean old logs or use the watchdog archiving |

---

## 🛠 The Watchdog Script

`utils/watchdog.ps1` continuously monitors a chosen VM and automatically:

1. Logs every state change to `C:\VBoxLogs\<VM_NAME>\watchdog.log`
2. When state ≠ `running`/`paused`:
   - Copies all `VBox*.log*` files
   - Exports Windows **System** and **Application** event logs (last 60 min)
   - Takes a live snapshot (`watchdog-YYYYMMDD-HHMMSS`)
   - Restarts the VM headless
3. Writes a timestamped diagnostic bundle under:

C:\VBoxLogs<VM_NAME><YYYYMMDD-HHMMSS>     
├─ VBox.log      
├─ VBox.log.1     
├─ System.evtx     
├─ Application.evtx     
├─ startvm.txt     
└─ state.txt     

---

```yaml
## ⚙️ Scheduling

To make it automatic:

1. Open **Task Scheduler** → *Create Task…*
2. Run:

```    

Program/script: powershell.exe     
```yaml
Arguments: -NoProfile -ExecutionPolicy Bypass -File "C:\users\paulo\documents\dev\hyperv-mapper\utils\watchdog.ps1" -VmName "WinDev2407Eval"

```

3. Configure:
- **Run whether user is logged on or not**
- **Run with highest privileges**
- Trigger every 2–5 minutes      

---

## 🧾 Log Example (Excerpt)


[2025-10-16 16:49:31Z] ---- Watchdog invoked for WinDev2407Eval ----     
[2025-10-16 16:49:31Z] Current state: aborted     
[2025-10-16 16:49:31Z] Collecting diagnostics...     
[2025-10-16 16:49:32Z] Snapshot watchdog-20251016-164931 created.     
[2025-10-16 16:49:33Z] Attempting restart...    
[2025-10-16 16:49:39Z] Post-restart state: running     


---

## 🧩 Why It Matters

The watchdog provides **a forensically complete trail** for diagnosing stability issues and ensures unattended labs, simulations, and training environments recover instantly.  

It’s especially useful in systems where **Hyper-V and VirtualBox coexist**, or where you experiment with **nested virtualization, GPU passthrough, or unstable driver stacks**.

---

## 🔐 Tip

If your logs repeatedly show hardening violations, test with:

```cmd
VBoxManage setextradata global GUI/HardenedRuntimeDisabled 1

```

⚠️ Use only for trusted hosts — this disables part of the anti-injection guard.

### ✅ Summary      

| Purpose	                         | File
|:-----------------------------------|:---------------------------------|
| Automatic recovery and log capture |	utils/watchdog.ps1               |
| Explanation and setup guide	       | docs/VirtualBox-Unknown-State.md |


### 🛡 Maintained by: Paulo H. Leocadio — Zinnia AI Software Engineering & Digital Design
