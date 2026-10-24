<# Read-only aggregate evidence. Never opens SQLite, device sockets or raw JSON payloads. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$StatusPath,
    [Parameter(Mandatory=$true)][string]$RuntimeDir,
    [Parameter(Mandatory=$true)][string]$OutboxDir,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [ValidateRange(1, 60)][int]$Samples = 7,
    [ValidateRange(0.1, 60)][double]$IntervalSeconds = 10
)
$ErrorActionPreference = 'Stop'
function Select-Fields($Object, [string[]]$Names) {
    $result = [ordered]@{}
    foreach ($name in $Names) { $result[$name] = $Object.$name }
    return $result
}
$report = [ordered]@{
    schema_version = 1
    collected_at_utc = [DateTime]::UtcNow.ToString('o')
    scope = 'Read-only aggregate evidence; status counters are historical when stale'
    samples = @()
}
for ($index = 0; $index -lt $Samples; $index++) {
    $now = [DateTimeOffset]::UtcNow
    $sample = [ordered]@{ observed_at_utc = $now.ToString('o'); status_read_error = $null }
    try {
        $status = [IO.File]::ReadAllText($StatusPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
        $sample.status = Select-Fields $status @(
            'build_id','state','generated_at_utc','service_instance_id','status_sequence',
            'uptime_seconds','writer_queue_depth','writer_queue_capacity','writer_native_id',
            'packets_committed','bytes_received','disk_free_bytes','database_bytes','last_error_code'
        )
        $sample.status_age_seconds = $null
        if ($status.generated_at_utc) {
            $sample.status_age_seconds = [math]::Round(($now - [DateTimeOffset]::Parse($status.generated_at_utc)).TotalSeconds, 3)
        }
        $sample.writer_progress = Select-Fields $status.writer_progress @(
            'current_command','command_age_seconds','commands_completed',
            'last_completion_age_seconds','stalled','stall_threshold_seconds'
        )
        $sample.ports = @($status.devices | ForEach-Object {
            Select-Fields $_ @('device_id','source_port','state','connections','reconnects',
                'silent_reconnects','bytes_received','packets_committed','last_packet_at_utc',
                'last_byte_age_seconds','last_error_code')
        })
        $sample.streams = @($status.streams | ForEach-Object {
            Select-Fields $_ @('device_id','active_source','stream_sequence','state',
                'last_user_packet_at_utc','last_service_packet_at_utc',
                'service_recovery_started_at_utc','service_recovery_packets','hold_down_until_utc')
        })
        $sample.framing = @($status.framing | ForEach-Object {
            Select-Fields $_ @('device_id','source_port','invalid_frames','discarded_bytes','buffered_bytes')
        })
    } catch { $sample.status_read_error = $_.Exception.GetType().Name }
    $report.samples += $sample
    if ($index -lt ($Samples - 1)) { Start-Sleep -Milliseconds ([int]($IntervalSeconds * 1000)) }
}
try {
    $service = Get-CimInstance Win32_Service -Filter "Name='PrismaFlexCollectorService'"
    $report.service = Select-Fields $service @('State','ProcessId','StartMode')
    $processes = @(Get-CimInstance Win32_Process -Filter "Name='PrismaFlexCollectorService.exe'")
    $report.processes = @($processes | ForEach-Object { Select-Fields $_ @('ProcessId','ParentProcessId','CreationDate','ThreadCount') })
    $ownedIds = @($processes | ForEach-Object { $_.ProcessId })
    $report.sockets = @(Get-NetTCPConnection -ErrorAction Stop | Where-Object {
        $_.OwningProcess -in $ownedIds -and $_.RemotePort -in @(3001,3002)
    } | ForEach-Object {
        [ordered]@{ owner_pid=$_.OwningProcess; remote_address=$_.RemoteAddress; remote_port=$_.RemotePort; state=[string]$_.State }
    })
} catch { $report.os_read_error = $_.Exception.GetType().Name }
$report.storage = [ordered]@{}
foreach ($name in @('collector_runtime.db','collector_runtime.db-wal','collector_runtime.db-shm')) {
    $path = Join-Path $RuntimeDir $name
    $report.storage[$name] = if (Test-Path -LiteralPath $path -PathType Leaf) { (Get-Item -LiteralPath $path).Length } else { $null }
}
$report.outbox = [ordered]@{ counted_at_utc=[DateTime]::UtcNow.ToString('o'); recursive_json_files=0; count_truncated=$false; oldest_write_utc=$null }
try {
    $readyDir = Join-Path $OutboxDir 'ready'
    if (Test-Path -LiteralPath $readyDir -PathType Container) {
        foreach ($file in [IO.Directory]::EnumerateFiles($readyDir, '*.json', [IO.SearchOption]::AllDirectories)) {
            $report.outbox.recursive_json_files++
            $stamp = [IO.File]::GetLastWriteTimeUtc($file).ToString('o')
            if (!$report.outbox.oldest_write_utc -or $stamp -lt $report.outbox.oldest_write_utc) { $report.outbox.oldest_write_utc = $stamp }
            if ($report.outbox.recursive_json_files -ge 100000) { $report.outbox.count_truncated = $true; break }
        }
    } else { $report.outbox.path_missing = $true }
} catch { $report.outbox.read_error = $_.Exception.GetType().Name }
$destination = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $destination) { throw 'Evidence output already exists; choose a new file.' }
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
[IO.File]::WriteAllText($destination, ($report | ConvertTo-Json -Depth 12), [Text.UTF8Encoding]::new($false))
Write-Output $destination
