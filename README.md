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
│
├── host/                # Scripts to run on the Hyper-V host
│   ├── setup-nat.ps1
│   ├── enable-rdp.ps1
│   └── ...
│
├── guest/               # Scripts to run inside the guest VM
│   ├── configure-firewall.ps1
│   ├── set-private-profile.ps1
│   └── ...
│
├── utils/               # Shared utilities
│   ├── test-connectivity.ps1
│   └── ...
│
├── docs/                # Documentation, diagrams, usage guides
│   └── README.md
│
├── .gitignore
└── README.md            # This file
