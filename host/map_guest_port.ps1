<#
.SYNOPSIS
  Maps a host external port to a guest VM RDP port.
#>

param(
    [string]$NatName   = "CustomNat",
    [string]$GuestIP   = "192.168.155.10",
    [int]$GuestPort    = 5389,
    [int]$HostPort     = 5389
)

# Remove old mapping
Get-NetNatStaticMapping -NatName $NatName -ErrorAction SilentlyContinue |
  Where-Object { $_.Protocol -eq 'TCP' -and $_.ExternalPort -eq $HostPort } |
  Remove-NetNatStaticMapping -Confirm:$false -ErrorAction SilentlyContinue

# Add mapping
Add-NetNatStaticMapping -NatName $NatName -Protocol TCP `
    -ExternalIPAddress "0.0.0.0" -ExternalPort $HostPort `
    -InternalIPAddress $GuestIP -InternalPort $GuestPort

Write-Host "Mapping created: host:$HostPort -> $GuestIP:$GuestPort" -ForegroundColor Green
