<#
.SYNOPSIS
  Sets custom RDP port inside the guest VM.
#>

param(
    [int]$Port = 5389
)

# Change registry key
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
    -Name "PortNumber" -Value $Port -Type DWord

# Restart service
Restart-Service -Name TermService -Force
Write-Host "RDP port changed to $Port" -ForegroundColor Green
