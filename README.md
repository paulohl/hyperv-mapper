# hyperv-mapper

Scripts to stand up Hyper-V Internal vSwitch + NAT and map RDP:
- Host RDP on :5055
- Guest RDP on :5389 via NAT (or explicit external binding)

See **docs/README.md** for usage and safety notes.

# 🔌 Hyper-V NAT & RDP Automation Lab

PowerShell scripts to automate **Hyper-V internal NAT networking** and **custom RDP port mapping**.  
Designed as a reproducible lab setup where the host exposes guest VMs through NAT with clean firewall and port-forward rules.

---

## 📦 Overview

This repo provides a modular script collection to:

- Create and manage **Hyper-V internal switches** with NAT.
- Assign host ↔ guest static IPs (e.g. `192.168.155.254` ↔ `192.168.155.10`).
- Map **host external RDP** to custom ports (default: `5055`) and guest RDP to `5389`.
- Configure guest firewall rules for RDP, ICMP, and custom ports.
- Validate connectivity with built-in test scripts.

---

## 🛠️ Prerequisites

- Windows 10/11 Pro or Windows Server with **Hyper-V** enabled.
- Administrative PowerShell session.
- A Hyper-V VM with:
  - Network adapter named `NAT-NIC`.
  - Guest OS with RDP enabled.
- Git (for cloning this repo).

---

## 📂 Folder Structure

```text
hyperv-mapper/

hyperv-nat-rdp-scripts/
├── README.md
├── LICENSE
├── host/
│   ├── setup-nat.ps1            # Create NAT, switch, and mappings
│   ├── reset-mapping.ps1        # Clear/rebuild port forwards
│   ├── verify-connectivity.ps1  # Sanity tests (ping, Test-NetConnection)
│   └── firewall-rules.ps1       # Manage Windows Firewall exceptions
├── guest/
│   ├── enable-rdp.ps1           # Set RDP port, firewall rules
│   ├── check-firewall.ps1       # Dump all remote desktop firewall rules
│   └── network-profile.ps1      # Force NIC profile to Private
├── utils/
│   ├── cleanup-switch.ps1       # Remove orphaned Hyper-V switches
│   ├── export-config.ps1        # Save NAT + firewall config snapshot
│   └── import-config.ps1        # Restore from snapshot
└── docs/
    ├── quickstart.md
    ├── troubleshooting.md
    └── architecture-diagram.png
```

---

🚀 Usage
1. Configure NAT on Host
host\create_nat.ps1

2. Add a Static RDP Mapping
host\map_rdp_port.ps1 -VmIP 192.168.155.10 -Port 5389

3. Prepare Guest for RDP

Inside the VM:

guest\enable_rdp.ps1
guest\firewall_rules.ps1

4. Test Connectivity
utils\test_nat.ps1 -VmIP 192.168.155.10 -Port 5389

---

🛡️ Security Notes

Only expose custom ports (e.g., 5055, 5389) instead of the default 3389.

Restrict access by IP if NAT is published externally.

Always confirm firewall rules are scoped to trusted networks.

Consider disabling RDP when not actively in use for production VMs.

---



---

# 🔌 Hyper-V NAT & RDP Automation Scripts

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue)](https://docs.microsoft.com/powershell/)
[![Hyper-V](https://img.shields.io/badge/Hyper--V-Windows%2010%2F11%20Pro%20%7C%20Server%202019+-orange)](https://docs.microsoft.com/virtualization/hyper-v-on-windows/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> **Fast-track remote access to Hyper-V guests**  
> This repository contains reusable PowerShell scripts to configure **Custom NAT networking** and **RDP redirection** on non-standard ports (e.g., `5389`).  
> Built from battle-tested troubleshooting sessions where pings failed, NAT mappings broke, and firewall rules went rogue — until everything finally clicked ⚡.

---

## 🧭 Architecture Flow

[ Host LAN IP (192.168.1.76) :5389 ]
│
NAT / Port Forward
│
[ Hyper-V Guest (192.168.155.10:5389) ]


_Note: Replace IPs/ports to fit your environment._

---

## 🚀 Quick Start

```powershell
# 1. Clone this repo
git clone https://github.com/<your-username>/hyperv-nat-rdp.git
cd hyperv-nat-rdp

# 2. Run NAT + Firewall setup
.\scripts\Setup-NAT-RDP.ps1

# 3. Verify connectivity
Test-NetConnection 192.168.155.10 -Port 5389
```

---

📂 Scripts Catalog

Setup-NAT-RDP.ps1 → Creates NAT, external address range, and static mapping (host:5389 → guest:5389).

Reset-NAT.ps1 → Cleans up existing NAT rules & reinitializes them.

Enable-RDP-Guest.ps1 → Opens RDP on the guest, adjusts registry PortNumber, and firewall.

Diagnostics.ps1 → Ping, TCP test, and ARP refresh to confirm connectivity.

---


🛠 Troubleshooting

| Symptom                             | Error Message                                                               | Fix                                                                  |
| ----------------------------------- | --------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| `TcpTestSucceeded : False`          | `Add-NetNatStaticMapping` says "does not match an existing ExternalAddress" | Recreate `ExternalAddress` binding with `0.0.0.0`                    |
| Guest pings host but not vice-versa | `Request timed out`                                                         | Check firewall profile (`Private`) and ICMP rules                    |
| RDP opens but no login screen       | NLA negotiation error                                                       | Ensure Remote Desktop is enabled + user is in `Remote Desktop Users` |

---

🤝 Contributing

Pull requests welcome — especially for new test cases, multi-VM mappings, or cross-host setups.
See CONTRIBUTING.md
 for details.

 ---

📜 License

MIT License © 2025 Zinnia Labs




