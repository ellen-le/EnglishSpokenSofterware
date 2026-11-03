param([string]$DevEcoRoot = 'F:\Apps\DevEco Studio')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$node = Join-Path $DevEcoRoot 'tools\node\node.exe'
$cli = Join-Path $DevEcoRoot 'tools\hvigor\hvigor\bin\hvigor.js'
foreach ($required in @($node, $cli, (Join-Path $DevEcoRoot 'sdk\default\sdk-pkg.json'))) {
  if (!(Test-Path -LiteralPath $required)) { throw "Required installed tool missing: $required" }
}
# Resolve the already installed IDE packages locally. No registry/download/install step.
foreach ($package in @('hvigor', 'hvigor-ohos-plugin')) {
  $source = Join-Path $DevEcoRoot "tools\hvigor\$package"
  $metadata = Get-Content -LiteralPath (Join-Path $source 'package.json') -Raw | ConvertFrom-Json
  $destination = Join-Path $projectRoot ".build-cache\modules\@ohos\$package"
  New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
  if (!(Test-Path -LiteralPath $destination)) {
    New-Item -ItemType Junction -Path $destination -Target $source | Out-Null
  }
}
$env:NODE_PATH = Join-Path $projectRoot '.build-cache\modules'
$env:DEVECO_SDK_HOME = Join-Path $DevEcoRoot 'sdk'
$env:JAVA_HOME = Join-Path $DevEcoRoot 'jbr'
$env:HVIGOR_USER_HOME = Join-Path $projectRoot '.build-cache'
Push-Location $projectRoot
try {
  & $node $cli --mode module -p product=default -p module=entry@default assembleHap --no-daemon --offline
  $result = $LASTEXITCODE
} finally { Pop-Location }
exit $result
