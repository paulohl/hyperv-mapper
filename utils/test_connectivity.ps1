<#
.SYNOPSIS
  Tests connectivity from host to guest.
#>

param(
    [string]$GuestIP = "192.168.155.10",
    [int]$Port = 5389
)

Write-Host "Pinging $GuestIP ..." -ForegroundColor Cyan
ping $GuestIP

Write-Host "Testing TCP port $Port ..." -ForegroundColor Cyan
Test-NetConnection $GuestIP -Port $Port
