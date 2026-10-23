<#
.SYNOPSIS
    Kiểm tra toàn diện trạng thái dịch vụ PrismaFlex Collector và kết nối mạng máy lọc.
.DESCRIPTION
    Script thực thi phía Target Agent trên máy chủ ICU-B để audit:
    - Trạng thái Windows Service PrismaFlexCollectorService
    - Lắng nghe cổng TCP (3001 User, 3002 Service)
    - Kiểm tra Ping tới 11 máy lọc (192.168.5.21 - 192.168.5.31)
    - Kích thước cơ sở dữ liệu SQLite và hàng đợi outbox
    - Xuất báo cáo tóm tắt Markdown
#>

param(
    [string]$CollectorDataDir = "C:\ProgramData\PrismaFlex\Collector",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Continue"

Write-Host "=== Bắt đầu kiểm tra PrismaFlex Collector Service ===" -ForegroundColor Cyan

# 1. Kiểm tra Windows Service
$service = Get-Service -Name "PrismaFlexCollectorService" -ErrorAction SilentlyContinue
$serviceStatus = if ($service) { $service.Status } else { "NOT_INSTALLED" }

$process = Get-Process -Name "PrismaFlexCollectorService" -ErrorAction SilentlyContinue
$procId = if ($process) { $process.Id } else { "N/A" }
$wsMb = if ($process) { [math]::Round($process.WorkingSet64 / 1MB, 2) } else { 0 }

Write-Host "Service Status: $serviceStatus (PID: $procId, Memory: $wsMb MB)" -ForegroundColor Yellow

# 2. Kiểm tra Port 3001 và 3002
$ports = @(3001, 3002)
$portResults = @{}
foreach ($p in $ports) {
    $conn = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $portResults[$p] = "LISTENING (PID: $($conn.OwningProcess | Select-Object -Unique))"
    } else {
        $portResults[$p] = "NOT_LISTENING"
    }
    Write-Host "Port $p: $($portResults[$p])"
}

# 3. Kiểm tra Ping 11 máy lọc PrismaFlex
$devices = @(
    @{ Id=1; Code="PF_001"; IP="192.168.5.21" },
    @{ Id=2; Code="PF_002"; IP="192.168.5.22" },
    @{ Id=3; Code="PF_003"; IP="192.168.5.23" },
    @{ Id=4; Code="PF_004"; IP="192.168.5.24" },
    @{ Id=5; Code="PF_005"; IP="192.168.5.25" },
    @{ Id=6; Code="PF_006"; IP="192.168.5.26" },
    @{ Id=7; Code="PF_007"; IP="192.168.5.27" },
    @{ Id=8; Code="PF_008"; IP="192.168.5.28" },
    @{ Id=9; Code="PF_009"; IP="192.168.5.29" },
    @{ Id=10; Code="PF_010"; IP="192.168.5.30" },
    @{ Id=11; Code="PF_011"; IP="192.168.5.31" }
)

$pingResults = @()
Write-Host "`nĐang ping kiểm tra 11 máy lọc máu..." -ForegroundColor Cyan
foreach ($dev in $devices) {
    $ping = Test-Connection -ComputerName $dev.IP -Count 1 -Quiet -ErrorAction SilentlyContinue
    $statusText = if ($ping) { "ONLINE" } else { "OFFLINE" }
    $pingResults += [PSCustomObject]@{
        Code = $dev.Code
        IP = $dev.IP
        Ping = $statusText
    }
    Write-Host "[$($dev.Code)] $($dev.IP): $statusText"
}

# 4. Kiểm tra dữ liệu và Outbox
$dbSizeMb = 0
$walSizeMb = 0
$readyFiles = 0

if (Test-Path $CollectorDataDir) {
    $dbFile = Get-ChildItem -Path $CollectorDataDir -Filter "*.db" -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 1
    if ($dbFile) { $dbSizeMb = [math]::Round($dbFile.Length / 1MB, 2) }

    $walFile = Get-ChildItem -Path $CollectorDataDir -Filter "*.db-wal" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($walFile) { $walSizeMb = [math]::Round($walFile.Length / 1MB, 2) }

    $outboxReady = Join-Path $CollectorDataDir "outbox\ready"
    if (Test-Path $outboxReady) {
        $readyFiles = (Get-ChildItem -Path $outboxReady -Filter "*.json" -ErrorAction SilentlyContinue).Count
    }
}

# 5. Xuất báo cáo Markdown
$nowStr = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$reportMd = @"
# Collector Quick Audit Report

- **Thời gian thực hiện**: $nowStr (GMT+7)
- **Máy chủ**: ICU-B (`192.168.5.1`)
- **Dịch vụ**: PrismaFlexCollectorService ($serviceStatus) | PID: $procId | RAM: $wsMb MB

## 1. Trạng thái Cổng Lắng nghe
- **User Port (3001)**: $($portResults[3001])
- **Service Port (3002)**: $($portResults[3002])

## 2. Kết nối Mạng 11 Thiết bị
| Thiết bị | IP | Ping |
|:---:|:---:|:---:|
$($pingResults | ForEach-Object { "| $($_.Code) | $($_.IP) | $($_.Ping) |" } | Out-String)

## 3. Lưu trữ & Hàng đợi
- **SQLite DB Size**: $dbSizeMb MB (WAL: $walSizeMb MB)
- **Outbox Ready Queue**: $readyFiles files còn chờ chuyển tiếp
"@

if ($OutputFile) {
    Set-Content -Path $OutputFile -Value $reportMd -Encoding utf8
    Write-Host "`nĐã lưu báo cáo tại: $OutputFile" -ForegroundColor Green
} else {
    Write-Host "`n$reportMd"
}
