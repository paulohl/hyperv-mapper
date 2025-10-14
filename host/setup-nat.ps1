<#
.SYNOPSIS
  Creates/repairs a Hyper-V Internal vSwitch + NAT and maps host:EXTERNAL → guest:INTERNAL RDP.

.DESCRIPTION
  - Ensures an Internal vSwitch exists (default: CustomNAT_A)
  - Assigns host vNIC IP (default: 192.168.155.254/24) and sets SkipAsSource:$false
  - Ensures a NAT object for the /24
  - Adds static mapping host:<ExternalPort> -> <GuestIP>:<GuestPort> (defaults 5389 → 5389)
  - Opens host firewall for the external port and ICMP (optional)

.NOTES
  Run as Administrator.
#>

[CmdletBinding()]
param(
  [string]$VSwitchName   = "CustomNAT_A",
  [string]$NatName       = "CustomNat",
  [string]$SubnetCidr    = "192.168.155.0/24",
  [string]$HostGatewayIP = "192.168.155.254",
  [string]$GuestIP       = "192.168.155.10",
  [int]   $ExternalPort  = 5389,          # what callers hit on the HOST
  [int]   $GuestPort     = 5389,          # what the GUEST listens on
  [string]$ExternalBind  = "0.0.0.0",     # use a specific LAN IP (e.g. 192.168.1.76) if you want to pin it
  [switch]$AllowIcmpIn                      # allow ping to the host vNIC
)

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Please run PowerShell as Administrator."
  }
}

try {
  Require-Admin
  Import-Module Hyper-V -ErrorAction Stop
} catch {
  Write-Error $_
  exit 1
}

Write-Host "`n=== [1/5] Ensure Internal vSwitch '$VSwitchName' exists ===" -ForegroundColor Cyan
$sw = Get-VMSwitch -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $VSwitchName -and $_.SwitchType -eq 'Internal' }
if (-not $sw) {
  $sw = New-VMSwitch -Name $VSwitchName -SwitchType Internal
  Start-Sleep 1
  Write-Host "Created Internal vSwitch: $($sw.Name)"
} else {
  Write-Host "Found Internal vSwitch: $($sw.Name)"
}

Write-Host "`n=== [2/5] Configure host vNIC IP on 'vEthernet ($VSwitchName)' ===" -ForegroundColor Cyan
$if = Get-NetAdapter | Where-Object { $_.Name -eq "vEthernet ($VSwitchName)" } | Select-Object -First 1
if (-not $if) { throw "Host vNIC 'vEthernet ($VSwitchName)' not found." }

# Remove any IPv4s from this adapter, then assign the gateway IP as Preferred (SkipAsSource:$false)
Get-NetIPAddress -InterfaceAlias $if.Name -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue | Out-Null

New-NetIPAddress -InterfaceAlias $if.Name -IPAddress $HostGatewayIP -PrefixLength 24 -SkipAsSource:$false | Out-Null
Write-Host "Assigned $HostGatewayIP/24 to $($if.Name) (Preferred)."

# Ensure a directly-connected route exists (Windows usually adds it, but we’re explicit)
if (-not (Get-NetRoute -DestinationPrefix $SubnetCidr -ErrorAction SilentlyContinue)) {
  New-NetRoute -DestinationPrefix $SubnetCidr -InterfaceIndex $if.ifIndex -NextHop 0.0.0.0 -RouteMetric 10 | Out-Null
  Write-Host "Added route $SubnetCidr via $($if.Name)"
}

Write-Host "`n=== [3/5] Ensure NAT '$NatName' covers $SubnetCidr ===" -ForegroundColor Cyan
$nat = Get-NetNat -Name $NatName -ErrorAction SilentlyContinue
if (-not $nat) {
  $nat = New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $SubnetCidr
  Write-Host "Created NAT: $NatName ($SubnetCidr)"
} else {
  Write-Host "Found NAT: $NatName ($($nat.InternalIPInterfaceAddressPrefix))"
}

Write-Host "`n=== [4/5] Map host:$ExternalBind:$ExternalPort → guest:$GuestIP:$GuestPort ===" -ForegroundColor Cyan
# Remove conflicting mappings for same port/IP
Get-NetNatStaticMapping -NatName $NatName -ErrorAction SilentlyContinue |
  Where-Object {
    $_.Protocol -eq 'TCP' -and (
      $_.ExternalPort -eq $ExternalPort -or
      ($_.InternalIPAddress -eq $GuestIP -and $_.InternalPort -eq $GuestPort)
    )
  } | Remove-NetNatStaticMapping -Confirm:$false -ErrorAction SilentlyContinue

Add-NetNatStaticMapping -NatName $NatName -Protocol TCP `
  -ExternalIPAddress $ExternalBind -ExternalPort $ExternalPort `
  -InternalIPAddress $GuestIP     -InternalPort  $GuestPort | Out-Null

Write-Host "Added NAT static mapping: $ExternalBind`:$ExternalPort → $GuestIP`:$GuestPort (TCP)."

Write-Host "`n=== [5/5] Host firewall rules ===" -ForegroundColor Cyan
$ruleName = "RDP to Guest via NAT ($ExternalPort)"
Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $ExternalPort -Action Allow | Out-Null
if ($AllowIcmpIn) {
  $icmpName = "Allow ICMPv4 In ($VSwitchName)"
  Get-NetFirewallRule -DisplayName $icmpName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
  New-NetFirewallRule -DisplayName $icmpName -Direction Inbound -Protocol ICMPv4 -Action Allow -Profile Any | Out-Null
}

Write-Host "`n=== STATUS ===" -ForegroundColor Green
Get-NetIPAddress -InterfaceAlias $if.Name -AddressFamily IPv4 | ft IPAddress,AddressState
Get-NetRoute -DestinationPrefix $SubnetCidr | ft DestinationPrefix,InterfaceAlias,NextHop,RouteMetric
Get-NetNat -Name $NatName
Get-NetNatStaticMapping -NatName $NatName | ft Protocol,ExternalIPAddress,ExternalPort,InternalIPAddress,InternalPort

Write-Host "`nTip: From another machine, connect to HOST_LAN_IP:$ExternalPort (guest RDP).`n" -ForegroundColor Yellow
