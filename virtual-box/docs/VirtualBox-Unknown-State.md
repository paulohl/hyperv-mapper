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

