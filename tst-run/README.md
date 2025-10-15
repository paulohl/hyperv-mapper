# SCENARIO / TEST LAB ENVIROMENT SET UP

A stable Hyper-V VM operating without problems (boots up, internal “virtual LAN”/default switch works), but the external network connection broke due to a faulty remapping of the v-netowrk adapter. Initial diagnosis points to the virtual switch bindings got lost or mismatched during the remapping (the team wants the VN to be mapped to a newly installed adapter). Here’s the proposed repair plan:

1. __Check the physical NIC__

Make sure the repaired server’s physical NIC is installed and working in Windows (check Device Manager and confirm it has a valid driver).

Confirm it has a live network connection (test by pinging the gateway or browsing the internet from the host itself).

2. __Inspect the Hyper-V Virtual Switches__

Open Hyper-V Manager → Virtual Switch Manager:

You’ll see one or more switches:

External – bound to a physical NIC.

Internal – host ↔ VM only.

Private – VM ↔ VM only.

Default Switch – NAT-based, works for internet but not LAN services.

If your VM only works on “virtual LAN,” you’re likely on the Default Switch or an Internal one.

👉 __Fix__:

If you need LAN/Internet connectivity, create or re-map an External switch:

Click New virtual network switch → External.

Bind it to the correct physical NIC.

(Optional) Tick “Allow management OS to share this adapter” so the host can use it too.

3. __Re-attach the VM’s NIC__

Go to VM Settings → Network Adapter.

Under “Virtual Switch,” select the External switch you just created.

Apply and restart the VM.

4. __Inside the VM__

Make sure the guest OS detects the NIC (in Device Manager/Network Connections).

Check IP config:

If DHCP: ipconfig /renew (Windows) or dhclient (Linux).

If static: re-enter the gateway/DNS manually.

5. __Test__

From the VM, ping the host and your LAN gateway.

If successful, test DNS resolution and internet.

✅ If this works, your VM will have normal LAN + internet.
❌ If it still only works with the Default Switch:

The physical NIC driver may be wrong or “team” (LBFO/SET) configuration broken.

Or, Hyper-V switch still bound to the wrong interface.

In that case, delete the External switch, reboot, and recreate it carefully bound to the correct NIC.    

_________________________

At this point, we move to Power Shell scripts to continue the troubleshooting process.
