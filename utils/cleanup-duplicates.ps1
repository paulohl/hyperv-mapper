<#
.SYNOPSIS
  Removes orphan duplicate 'CustomNAT' switches (keeps Default Switch and CustomNAT_A).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
  [string]$KeepName = "CustomNAT_A"
)

$toRemove = Get-VMSwitch | Where-Object {
  $_.Name -eq "CustomNAT" -and $_.Name -ne $KeepName
}

if (-not $toRemove) {
  Write-Host "No duplicate 'CustomNAT' switches to remove."
  return
}

foreach ($sw in $toRemove) {
  Write-Host "Attempting to remove duplicate switch $($sw.Id) ($($sw.Name))..." -ForegroundColor Yellow
  try {
    if ($PSCmdlet.ShouldProcess($sw.Name, "Remove-VMSwitch")) {
      Remove-VMSwitch -Id $sw.Id -Force
      Write-Host "Removed $($sw.Id)" -ForegroundColor Green
    }
  } catch {
    Write-Warning "Skip in-use switch $($sw.Id): $($_.Exception.Message)"
  }
}

Write-Host "`nRemaining switches:" -ForegroundColor Cyan
Get-VMSwitch | ft Name,Id,SwitchType
