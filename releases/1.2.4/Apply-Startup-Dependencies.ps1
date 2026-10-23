<# Apply dependencies from the signed 1.2.4 release after an upgrade driven by the old 1.2.1 updater. #>
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InstallRoot)
$ErrorActionPreference = 'Stop'
if (-not [IO.Path]::IsPathRooted($InstallRoot)) { throw 'Use an absolute install root' }
$root = (Resolve-Path -LiteralPath $InstallRoot).Path.TrimEnd('\')
$state = Get-Content -LiteralPath (Join-Path $root 'shared\install-state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$journal = Get-Content -LiteralPath (Join-Path $root 'shared\update.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($state.active_version -ne '1.2.4' -or $state.phase -ne 'READY' -or $journal.phase -ne 'HEALTHY') {
    throw 'Apply dependencies only after 1.2.4 is active, READY and HEALTHY'
}
$release = Join-Path $root 'releases\1.2.4'
$exe = Join-Path $release 'api\prismaflex.exe'
& $exe verify-release --directory $release --deployment | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Signed active release failed verification' }
$metadata = Get-Content -LiteralPath (Join-Path $release 'release.json') -Raw -Encoding UTF8 | ConvertFrom-Json
Import-Module (Join-Path $release 'deployment\Release.Common.psm1') -Force
foreach ($component in @('api','web','analyzer')) {
    $name = 'prismaflex-' + $component
    Assert-PFServiceOwnership $root $name
}
Write-PFServices $root $metadata
foreach ($component in @('api','web','analyzer')) {
    Sync-PFServiceDependencies $root ('prismaflex-' + $component)
}
Write-Output 'Startup dependencies applied to WinSW XML and Windows SCM; verify with Inspect-Target -Phase After before reboot.'
