<#
.SYNOPSIS
  Shows quick status for switches, NAT, and listeners.
#>

[CmdletBinding()]
param(
  [string]$VSwitchName = "CustomNAT_A",
  [string]$NatName     = "CustomNat"
)

Write-Host "=== Switches ===" -ForegroundColor Cyan
Get-VMSwitch | ft Name,SwitchType,Id

Write-Host "`n=== VM NICs ===" -ForegroundColor Cyan
Get-VMNetworkAdapter -ErrorAction SilentlyContinue | ft VMName,Name,SwitchName,IsConnected

Write-Host "`n=== NAT ===" -ForegroundColor Cyan
Get-NetNat -Name $NatName -ErrorAction SilentlyContinue
Get-NetNatStaticMapping -NatName $NatName -ErrorAction SilentlyContinue |
  ft Protocol,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort

Write-Host "`n=== vNIC IPs ===" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like "vEthernet ($VSwitchName)" } |
  ft InterfaceAlias,IPAddress,AddressState,PrefixLength

Write-Host "`n=== Listeners (RDP) ===" -ForegroundColor Cyan
netstat -ano | findstr LISTENING | findstr ":3389 :5055 :5389"
