Got it — let’s work through this step by step.

It sounds like your Hyper-V VM itself is fine (boots up, internal “virtual LAN”/default switch works), but the external network connection broke when you remapped the adapter. That usually means the virtual switch bindings got lost or mismatched. Here’s how you can fix it:

---

## 1. Check your physical NIC

* Make sure the repaired server’s **physical NIC is installed and working** in Windows (check Device Manager and confirm it has a valid driver).
* Confirm it has a live network connection (test by pinging the gateway or browsing the internet from the host itself).

---

## 2. Inspect the Hyper-V Virtual Switches

Open **Hyper-V Manager** → `Virtual Switch Manager`:

* You’ll see one or more switches:

  * **External** – bound to a physical NIC.
  * **Internal** – host ↔ VM only.
  * **Private** – VM ↔ VM only.
  * **Default Switch** – NAT-based, works for internet but not LAN services.
* If your VM only works on “virtual LAN,” you’re likely on the *Default Switch* or an Internal one.

👉 Fix:

* If you need LAN/Internet connectivity, **create or re-map an External switch**:

  1. Click **New virtual network switch → External**.
  2. Bind it to the correct physical NIC.
  3. (Optional) Tick “Allow management OS to share this adapter” so the host can use it too.

---

## 3. Re-attach the VM’s NIC

* Go to **VM Settings → Network Adapter**.
* Under “Virtual Switch,” select the External switch you just created.
* Apply and restart the VM.

---

## 4. Inside the VM

* Make sure the guest OS detects the NIC (in Device Manager/Network Connections).
* Check IP config:

  * If DHCP: `ipconfig /renew` (Windows) or `dhclient` (Linux).
  * If static: re-enter the gateway/DNS manually.

---

## 5. Test

* From the VM, ping the host and your LAN gateway.
* If successful, test DNS resolution and internet.

---

✅ If this works, your VM will have normal LAN + internet.
❌ If it still only works with the Default Switch:

* The physical NIC driver may be wrong or “team” (LBFO/SET) configuration broken.
* Or, Hyper-V switch still bound to the wrong interface.
* In that case, delete the External switch, reboot, and recreate it carefully bound to the correct NIC.

---

Would you like me to give you **PowerShell commands** that directly rebuild the switch (often faster and cleaner than Hyper-V Manager)? That way we can ensure all ghost bindings are wiped and recreated.
