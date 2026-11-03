param(
  [ValidateSet('List', 'Install', 'Start', 'Restart', 'Update')][string]$Action = 'List',
  [string]$DevEcoRoot = 'F:\Apps\DevEco Studio',
  [string]$Target = '127.0.0.1:5555'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$hdc = Join-Path $DevEcoRoot 'sdk\default\openharmony\toolchains\hdc.exe'
if (!(Test-Path -LiteralPath $hdc)) { throw 'Installed hdc not found.' }
Write-Output (Get-Date -Format o)
if ($Action -eq 'List') {
  & $hdc list targets
} elseif ($Action -eq 'Install') {
  & $hdc -t $Target install (Join-Path $projectRoot 'entry\build\default\outputs\default\entry-default-unsigned.hap')
} else {
  if ($Action -eq 'Update') {
    & $hdc -t $Target install (Join-Path $projectRoot 'entry\build\default\outputs\default\entry-default-unsigned.hap')
    if ($LASTEXITCODE -ne 0) { throw 'Install failed.' }
  }
  if ($Action -eq 'Restart' -or $Action -eq 'Update') {
    & $hdc -t $Target shell aa force-stop com.oscom.speaking
    if ($LASTEXITCODE -ne 0) { throw 'Force-stop failed.' }
  }
  & $hdc -t $Target shell aa start -a EntryAbility -b com.oscom.speaking
}
exit $LASTEXITCODE
