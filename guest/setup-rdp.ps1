<#
.SYNOPSIS
  Configures Windows guest for RDP on a custom port (default 5389) and opens firewall.

.NOTES
  Run as Administrator inside the VM.
#>

[CmdletBinding()]
param(
  [int]$RdpPort = 5389,
  [string]$InterfaceName = "Ethernet 10",  # Adjust if your guest NIC shows a different name
  [switch]$SetProfilePrivate               # Force network profile to Private
)

function Require-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw "Please run PowerShell as Administrator."
  }
}

Require-Admin

Write-Host "=== Enable RDP and set port to $RdpPort ===" -ForegroundColor Cyan
# Enable RDP
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f | Out-Null

# Set custom port
$rdpKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
Set-ItemProperty -Path $rdpKey -Name PortNumber -Type DWord -Value $RdpPort

Write-Host "=== Open firewall for Remote Desktop + TCP $RdpPort ===" -ForegroundColor Cyan
# Built-in RDP group
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes | Out-Null
# Explicit port
$ruleName = "RDP $RdpPort (TCP-In)"
netsh advfirewall firewall delete rule name="$ruleName" | Out-Null
netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=$RdpPort | Out-Null

if ($SetProfilePrivate) {
  try {
    Set-NetConnectionProfile -InterfaceAlias $InterfaceName -NetworkCategory Private -ErrorAction Stop
    Write-Host "Forced '$InterfaceName' to Private profile." -ForegroundColor Yellow
  } catch {
    Write-Warning "Could not set network category for '$InterfaceName' automatically: $($_.Exception.Message)"
  }
}

Write-Host "=== Restart TermService to apply the new port ===" -ForegroundColor Cyan
try { Restart-Service -Name TermService -Force -ErrorAction Stop }
catch { Write-Warning "Restart-Service failed, a reboot might be required." }

Write-Host "`n=== Verify listeners ===" -ForegroundColor Green
netstat -an | findstr ":$RdpPort"

Write-Host "`nDone. You should be able to RDP to this VM on $env:COMPUTERNAME:$RdpPort (or via NAT on the host)." -ForegroundColor Green
