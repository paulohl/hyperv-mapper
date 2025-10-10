<#
.SYNOPSIS
  Creates a NAT switch and gateway for Hyper-V.
#>

param(
    [string]$SwitchName = "CustomNAT_A",
    [string]$NatName = "CustomNat",
    [string]$Gateway = "192.168.155.254",
    [string]$Subnet  = "192.168.155.0/24"
)

# Create internal switch if not exists
if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    New-VMSwitch -SwitchName $SwitchName -SwitchType Internal
}

# Assign IP to host vNIC
$if = Get-NetAdapter | Where-Object { $_.Name -eq "vEthernet ($SwitchName)" }
if ($if) {
    if (-not (Get-NetIPAddress -InterfaceAlias $if.Name -IPAddress $Gateway -ErrorAction SilentlyContinue)) {
        New-NetIPAddress -InterfaceAlias $if.Name -IPAddress $Gateway -PrefixLength 24 -SkipAsSource $false
    }
}

# Recreate NAT
Get-NetNat -Name $NatName -ErrorAction SilentlyContinue | Remove-NetNat -Confirm:$false
New-NetNat -Name $NatName -InternalIPInterfaceAddressPrefix $Subnet

Write-Host "NAT created: $NatName ($Subnet via $Gateway)" -ForegroundColor Green

