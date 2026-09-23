<# Read-only preflight/postflight. Never stops services or changes the installation. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$PackageDir,
    [ValidateSet('Before','After')][string]$Phase = 'Before',
    [string]$ReportPath
)
$ErrorActionPreference = 'Stop'
$checks = [Collections.Generic.List[object]]::new()
function Check([string]$Name, [bool]$Passed, [string]$Detail) {
    $checks.Add([pscustomobject]@{ check=$Name; result=$(if ($Passed) {'PASS'} else {'FAIL'}); detail=$Detail })
}
function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function ReadJson([string]$Path) {
    Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}
function CommandJson([string]$Exe, [string[]]$Arguments) {
    # Raw command errors can contain connection information. Emit only exit code.
    $raw = @(& $Exe @Arguments 2>&1)
    Require ($LASTEXITCODE -eq 0) "Release command failed (exit $LASTEXITCODE); inspect locally"
    ($raw -join "`n") | ConvertFrom-Json
}
try {
    Require ([IO.Path]::IsPathRooted($InstallRoot) -and [IO.Path]::IsPathRooted($PackageDir)) 'Use absolute local paths'
    $root = (Resolve-Path -LiteralPath $InstallRoot).Path.TrimEnd('\')
    $package = (Resolve-Path -LiteralPath $PackageDir).Path.TrimEnd('\')
    $state = ReadJson (Join-Path $root 'shared\install-state.json')
    Require ($state.active_version -match '^\d+\.\d+\.\d+$') 'Invalid active version'
    Require ($state.management_protocol -eq 2) 'This handoff expects protocol 2; legacy install needs a separate procedure'
    Require ($state.phase -eq 'READY') 'Installation is not READY; recover the existing operation first'
    $oldDir = Join-Path $root ("releases\{0}" -f $state.active_version)
    $exe = Join-Path $oldDir 'api\prismaflex.exe'
    $old = (CommandJson $exe @('verify-release','--directory',$oldDir,'--deployment')).deployment
    $candidate = (CommandJson $exe @('verify-release','--directory',$package,'--deployment')).deployment
    Require ($candidate.version -eq '1.2.3' -and -not $candidate.test_only) 'Expected signed 1.2.3 production-key package'
    Check 'signed_package' $true 'Installed verifier accepts current and candidate releases'
    Check 'site_and_features' ($candidate.site_profile_hash -eq $old.site_profile_hash -and $candidate.analyzer_enabled -eq $old.analyzer_enabled) 'Same site profile and Analyzer feature required for this handoff'
    if ($Phase -eq 'Before') {
        Check 'newer_version' ([version]$candidate.version -gt [version]$state.active_version) "Installed $($state.active_version), candidate $($candidate.version)"
        Check 'candidate_not_staged' (-not (Test-Path -LiteralPath (Join-Path $root 'releases\1.2.3'))) 'Existing version directory must not be overwritten; inspect any earlier attempt'
    } else {
        Check 'selected_version' ($state.active_version -eq '1.2.3') "Installed $($state.active_version)"
    }
    $journalPath = Join-Path $root 'shared\update.json'
    if (Test-Path -LiteralPath $journalPath) {
        $journal = ReadJson $journalPath
        $allowed = if ($Phase -eq 'After') { @('HEALTHY') } else { @('HEALTHY','ROLLED_BACK','RESTORED') }
        Check 'update_state' ($journal.phase -in $allowed) "Phase $($journal.phase)"
    } else {
        Check 'update_state' ($Phase -eq 'Before') 'No update journal'
    }
    $license = CommandJson $exe @('--install-root',$root,'license-status')
    Check 'license' ($license.status -eq 'active') 'License command succeeded; identity omitted'
    $db = CommandJson $exe @('--install-root',$root,'db-revision')
    Check 'database_revision' (@($db.revisions).Count -eq 1 -and $db.revisions[0] -eq $old.db_revision -and $db.revisions[0] -in $candidate.supported_from_revisions) 'Expected revision d4b2a8f91c30'
    $ready = CommandJson $exe @('--install-root',$root,'ready')
    Check 'readiness_command' ($ready.status -eq 'ready' -and $ready.version -eq $state.active_version) 'DB/schema/reference/license admission only; services checked below'
    foreach ($tool in @('pg_dump.exe','pg_restore.exe')) {
        Check $tool (Test-Path -LiteralPath (Join-Path $state.pg_bin $tool) -PathType Leaf) 'PostgreSQL backup tools must exist at install-state.pg_bin'
    }
    $components = @('api','web')
    if ($candidate.analyzer_enabled) { $components += 'analyzer' }
    foreach ($component in $components) {
        $name = 'prismaflex-' + $component
        $service = Get-CimInstance Win32_Service -Filter "Name='$name'"
        $expected = Join-Path $root "service\$name.exe"
        Check $name ($null -ne $service -and $service.PathName.Trim('"') -eq $expected -and $service.State -eq 'Running') 'Must be Running and owned by this install root'
    }
    $runtime = ReadJson (Join-Path $root 'shared\config\runtime.json')
    $apiReady = Invoke-RestMethod -Uri ("http://127.0.0.1:{0}/internal/ready" -f $runtime.PORT) -TimeoutSec 15
    Check 'live_api_workers' ($apiReady.status -eq 'ready' -and $apiReady.version -eq $state.active_version) 'Live API/worker readiness matches selected version'
    $login = Invoke-WebRequest -UseBasicParsing -Uri ("http://127.0.0.1:{0}/login" -f $runtime.WEB_PORT) -TimeoutSec 15
    Check 'web_login_page' ($login.StatusCode -eq 200) 'Page availability only; human/agent login check remains required'
    if ($candidate.analyzer_enabled) {
        $analyzerPort = if ($runtime.ANALYZER_PORT) { [int]$runtime.ANALYZER_PORT } else { 15555 }
        $health = Invoke-RestMethod -Uri ("http://127.0.0.1:{0}/health" -f $analyzerPort) -TimeoutSec 15
        Check 'analyzer_http' ($health.status -eq 'ok') 'Analyzer health endpoint'
    }
    $volume = Get-PSDrive -Name ([IO.Path]::GetPathRoot($root).Substring(0,1))
    Check 'disk_minimum' ($volume.Free -gt 2GB) ('Free GB: {0:N1}; also budget DB dump plus shared/var and media copies' -f ($volume.Free/1GB))
} catch {
    # Do not serialize exception text, which may carry credentials or runtime data.
    Check 'preflight_completed' $false 'A check could not complete. Inspect paths, state and commands locally; do not update while any check fails.'
}
$report = [ordered]@{
    checked_at_utc=[DateTime]::UtcNow.ToString('o'); phase=$Phase; target_version='1.2.3'
    status=$(if (@($checks | Where-Object result -eq 'FAIL').Count) {'BLOCKED'} else {'PASS'})
    checks=@($checks.ToArray())
    manual_checks=@('Confirm maintenance window and OIE retry/backlog handling','Budget disk for actual DB and runtime backup','Login and inspect telemetry/chart/journal','Keep diagnostic details and patient data off public GitHub')
}
$json = $report | ConvertTo-Json -Depth 8
if ($ReportPath) {
    Require (-not (Test-Path -LiteralPath $ReportPath)) 'Choose a new report filename'
    [IO.File]::WriteAllText([IO.Path]::GetFullPath($ReportPath), $json, [Text.UTF8Encoding]::new($false))
}
$json
if ($report.status -ne 'PASS') { exit 2 }
exit 0
