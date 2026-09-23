[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Destination,
    [string]$ArchivePath
)
$ErrorActionPreference = 'Stop'
$meta = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ARTIFACT.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not [IO.Path]::IsPathRooted($Destination) -or (Test-Path -LiteralPath $Destination)) {
    throw 'Choose a new absolute destination directory; existing media is not overwritten'
}
$destinationRoot = [IO.Path]::GetFullPath($Destination)
$null = New-Item -ItemType Directory -Path $destinationRoot
$archive = Join-Path $destinationRoot $meta.filename
if ($ArchivePath) {
    Copy-Item -LiteralPath $ArchivePath -Destination $archive
} else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri $meta.url -OutFile $archive
}
if ((Get-Item -LiteralPath $archive).Length -ne $meta.bytes -or (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $meta.sha256) {
    throw 'Package size/hash mismatch; do not extract or execute'
}
$expanded = Join-Path $destinationRoot 'expanded'
Expand-Archive -LiteralPath $archive -DestinationPath $expanded
$package = Join-Path $expanded 'PrismaFlex-1.2.3-windows-x64\release'
if (-not (Test-Path -LiteralPath (Join-Path $package 'release.manifest.json'))) { throw 'Release layout missing' }
[pscustomobject]@{ version='1.2.3'; sha256=$meta.sha256; PackageDir=$package; next='Run Inspect-Target with the installed verifier before updating' } | ConvertTo-Json
