# docs

---

### 🚀 Usage
1. Configure NAT on Host 
 
  ```
host\create_nat.ps1

```

2. Add a Static RDP Mapping
```
host\map_rdp_port.ps1-VmIP 192.168.155.10 -Port 5389

```
3. Prepare Guest for RDP

Inside the VM:
```
guest\enable_rdp.ps1
guest\firewall_rules.ps1

```
4. Test Connectivity
```
utils\test_nat.ps1 -VmIP 192.168.155.10 -Port 5389

```
---
