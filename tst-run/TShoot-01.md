Further diagnosis: when the server came back online after hardware repair,    
the old switch bindings were invalid (because Hyper-V ties a switch to a specific NIC hardware ID).   
By re-mapping, you ended up with “dangling” or mismatched switches.

The cleanest fix is to wipe the broken switches and rebuild them fresh.   
To proceed safely: it will not delete the VMs, just the networking config.    

\
🔧 __Step 1: See what’s there now__

Open PowerShell (Admin) on the host and run:
```bash
Get-VMSwitch

```

This will list all current virtual switches and what adapters they’re bound to. Look for:

- Type = External/Internal/Private

- NetAdapterInterfaceDescription = the physical NIC (if any)

You’ll likely see one or more with blank or wrong bindings.

🔧 __Step 2: Remove the broken switches__

For each bad one:    
```bash
Remove-VMSwitch -Name "BrokenSwitchName" -Force

```

🔧 __Step 3: Create a new External switch__

Replace "Ethernet" with the actual name of your working physical NIC:   
```bash
New-VMSwitch -Name "ExternalLAN" -NetAdapterName "Ethernet" -AllowManagementOS $true

```

-AllowManagementOS $true lets the host also use this NIC (usually what you want).

If the server has multiple NICs, choose the one connected to your LAN/internet.   


🔧 __Step 4: Re-attach your VM__    

Open Hyper-V Manager → VM Settings → Network Adapter

Under “Virtual Switch,” select ExternalLAN (the new one).   


🔧 __Step 5: Verify inside the VM___

In the guest OS:

Run ipconfig /all (Windows) or ip a (Linux).

If DHCP is enabled, renew the lease:

Windows: ipconfig /renew
=======  

Linux: dhclient
=====   

Check you can reach the host and your network gateway.

⚡ __Safety tip__

If you’re nervous about cutting host connectivity, you can create the switch with -AllowManagementOS $false first,    
then add a second NIC (USB or iDRAC/iLO) to avoid locking yourself out of the host.
