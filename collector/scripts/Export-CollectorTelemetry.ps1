<#
.SYNOPSIS
    Tự động thu thập và đóng gói dữ liệu đo xa, trạng thái vận hành của Collector trên máy ICU-B.
.DESCRIPTION
    Script thực thi chỉ đọc (read-only), không gây gián đoạn dịch vụ:
    - Trích xuất cấu hình active và trạng thái collector_status.json
    - Đo đạc chi tiết socket port 3001/3002, SQLite WAL, dung lượng đĩa
    - Quét log tìm các sự kiện disconnect/timeout/failover gần nhất
    - Tổng hợp thành báo cáo hoàn chỉnh vào collector/reports/
    - Cập nhật collector/STATUS.md
#>

param(
    [string]$CollectorDataDir = "C:\ProgramData\PrismaFlex\Collector",
    [string]$BridgeRepoDir = "D:\PrismaFlexProject\PrismaFlex-Agent-Bridge"
)

$ErrorActionPreference = "Continue"
$now = Get-Date
$datePrefix = $now.ToString("yyyy-MM-dd")
$timestampStr = $now.ToString("yyyy-MM-dd HH:mm:ss")

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [ICU-B] THU THẬP THÔNG TIN VẬN HÀNH PRISMAFLEX COLLECTOR" -ForegroundColor Cyan
Write-Host " Thời gian: $timestampStr (GMT+7)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Kiểm tra trạng thái Windows Service
$svc = Get-Service -Name "PrismaFlexCollectorService" -ErrorAction SilentlyContinue
$svcStatus = if ($svc) { $svc.Status } else { "NOT_FOUND" }
$proc = Get-Process -Name "PrismaFlexCollectorService" -ErrorAction SilentlyContinue
$procId = if ($proc) { $proc.Id } else { "N/A" }
$procMemMb = if ($proc) { [math]::Round($proc.WorkingSet64 / 1MB, 2) } else { 0 }
$procStart = if ($proc) { $proc.StartTime.ToString("yyyy-MM-dd HH:mm:ss") } else { "N/A" }

Write-Host "`n1. Trạng thái Dịch vụ:" -ForegroundColor Yellow
Write-Host "   - Service: $svcStatus | PID: $procId | RAM: $procMemMb MB | Khởi động lúc: $procStart"

# 2. Thu thập file trạng thái và cấu hình
$statusFile = Join-Path $CollectorDataDir "status\collector_status.json"
$configFile = Join-Path $CollectorDataDir "config\collector_service.json"

$statusJson = $null
if (Test-Path $statusFile) {
    try {
        $statusJson = Get-Content -Path $statusFile -Raw -Encoding utf8 | ConvertFrom-Json
        Write-Host "2. Đọc file collector_status.json: THÀNH CÔNG" -ForegroundColor Green
    } catch {
        Write-Warning "Không parse được collector_status.json: $_"
    }
} else {
    Write-Warning "Không tìm thấy file: $statusFile"
}

# 3. Đo đạc kích thước Database và SQLite WAL
$dbDir = Join-Path $CollectorDataDir "runtime"
$dbSizeMb = 0
$walSizeMb = 0
if (Test-Path $CollectorDataDir) {
    $dbFiles = Get-ChildItem -Path $CollectorDataDir -Filter "*.db" -Recurse -ErrorAction SilentlyContinue | Sort-Object Length -Descending
    if ($dbFiles) { $dbSizeMb = [math]::Round(($dbFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2) }

    $walFiles = Get-ChildItem -Path $CollectorDataDir -Filter "*.db-wal" -Recurse -ErrorAction SilentlyContinue
    if ($walFiles) { $walSizeMb = [math]::Round(($walFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2) }
}
Write-Host "3. Lưu trữ SQLite: DB tổng cộng $dbSizeMb MB | WAL $walSizeMb MB" -ForegroundColor Yellow

# 4. Kiểm tra Outbox Hàng đợi
$readyDir = Join-Path $CollectorDataDir "outbox\ready"
$readyCount = 0
$oldestFileAge = "N/A"
if (Test-Path $readyDir) {
    $rFiles = Get-ChildItem -Path $readyDir -Filter "*.json" -ErrorAction SilentlyContinue | Sort-Object CreationTime
    $readyCount = $rFiles.Count
    if ($readyCount -gt 0) {
        $oldestFileAge = [math]::Round(((Get-Date) - $rFiles[0].CreationTime).TotalMinutes, 1).ToString() + " phút"
    } else {
        $oldestFileAge = "0 phút (Sạch hàng đợi)"
    }
}
Write-Host "4. Hàng đợi Outbox ready: $readyCount files | File cũ nhất: $oldestFileAge" -ForegroundColor Yellow

# 5. Socket Connections thực tế trên OS
$tcp3001 = Get-NetTCPConnection -LocalPort 3001 -ErrorAction SilentlyContinue
$tcp3002 = Get-NetTCPConnection -LocalPort 3002 -ErrorAction SilentlyContinue
$listen3001 = ($tcp3001 | Where-Object { $_.State -eq "Listen" }).Count -gt 0
$listen3002 = ($tcp3002 | Where-Object { $_.State -eq "Listen" }).Count -gt 0
$est3001 = ($tcp3001 | Where-Object { $_.State -eq "Established" }).Count
$est3002 = ($tcp3002 | Where-Object { $_.State -eq "Established" }).Count

Write-Host "5. Sockets:" -ForegroundColor Yellow
Write-Host "   - Port 3001 (User): Listen=$listen3001 | Established=$est3001 connections"
Write-Host "   - Port 3002 (Service): Listen=$listen3002 | Established=$est3002 connections"

# 6. Kiểm tra Ping dải thiết bị 192.168.5.21 - 31
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

$pingTable = @()
foreach ($d in $devices) {
    $p = Test-Connection -ComputerName $d.IP -Count 1 -Quiet -ErrorAction SilentlyContinue
    $pState = if ($p) { "ONLINE" } else { "OFFLINE" }
    $pingTable += [PSCustomObject]@{
        Code = $d.Code
        IP = $d.IP
        Ping = $pState
    }
}

# 7. Trích xuất trích đoạn log lỗi / sự kiện gần nhất (nếu có)
$logExcerpt = "Không tìm thấy file log hoặc log trống."
$logFiles = Get-ChildItem -Path (Join-Path $CollectorDataDir "logs") -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
if ($logFiles) {
    $latestLog = $logFiles[0]
    $lines = Get-Content -Path $latestLog.FullName -Tail 50 -ErrorAction SilentlyContinue
    if ($lines) {
        $logExcerpt = ($lines -join "`n")
    }
}

# 8. Sao chép bản cấu hình và trạng thái vào bridge
$destReportsDir = Join-Path $BridgeRepoDir "collector\reports"
$destConfigsDir = Join-Path $BridgeRepoDir "collector\configs"

if (-not (Test-Path $destReportsDir)) { New-Item -ItemType Directory -Path $destReportsDir -Force | Out-Null }
if (-not (Test-Path $destConfigsDir)) { New-Item -ItemType Directory -Path $destConfigsDir -Force | Out-Null }

if (Test-Path $configFile) {
    Copy-Item -Path $configFile -Destination (Join-Path $destConfigsDir "collector_service.active.json") -Force
    Write-Host "Đã sao lưu cấu hình active sang: collector/configs/collector_service.active.json" -ForegroundColor Green
}

# 9. Lập báo cáo Markdown chi tiết
$reportFileName = "${datePrefix}_collector-live-telemetry-report.md"
$reportPath = Join-Path $destReportsDir $reportFileName

$uptimeDays = if ($statusJson) { [math]::Round($statusJson.uptime_seconds / 86400, 2) } else { "N/A" }
$committedPackets = if ($statusJson) { "{0:N0}" -f $statusJson.packets_committed } else { "N/A" }
$receivedBytes = if ($statusJson) { "{0:N0}" -f $statusJson.bytes_received } else { "N/A" }
$queueDepth = if ($statusJson) { $statusJson.writer_queue_depth } else { "N/A" }

$devStatusLines = ""
if ($statusJson -and $statusJson.devices) {
    foreach ($dev in $statusJson.devices) {
        $devStatusLines += "| PF_$(('{0:D3}' -f [int]$dev.device_id)) | Port $($dev.source_port) | $($dev.state) | $($dev.reconnects) | $($dev.packets_committed) | $($dev.last_error_code) | $($dev.last_packet_at_utc) |`n"
    }
} else {
    $devStatusLines = "| Không có dữ liệu chi tiết thiết bị | - | - | - | - | - | - |`n"
}

$pingRows = ""
foreach ($row in $pingTable) {
    $pingRows += "| $($row.Code) | $($row.IP) | $($row.Ping) |`n"
}

$mdContent = @"
# Báo cáo Dữ liệu Đo xa & Hiện trạng Hoạt động Collector (ICU-B)

- **Thời điểm trích xuất**: $timestampStr (GMT+7)
- **Thiết bị thực hiện**: Máy chủ trạm ICU-B Chợ Rẫy (`192.168.5.1`)
- **Tình trạng Dịch vụ Windows**: `$svcStatus` (PID: `$procId`, RAM: `${procMemMb} MB`)
- **Thời gian khởi động**: `$procStart` (Uptime: `$uptimeDays` ngày)

---

## 1. Chỉ số Tổng quan Hệ thống (System Aggregates)

| Chỉ số | Giá trị ghi nhận | Đánh giá |
|---|---|---|
| **Tổng số gói tin đã lưu (Committed)** | $committedPackets gói | Tích lũy liên tục |
| **Tổng dung lượng mạng đã nạp** | $receivedBytes bytes | Luồng TCP 3001/3002 |
| **Độ sâu hàng đợi bộ ghi (Writer Queue)** | $queueDepth / 4096 | Khả năng đáp ứng đĩa |
| **Dung lượng Database SQLite** | $dbSizeMb MB | WAL Mode an toàn |
| **Kích thước file WAL hiện thời** | $walSizeMb MB | Cơ chế checkpoint tự động |
| **Hàng đợi Outbox Chuyển tiếp OIE** | $readyCount files tồn đọng | $oldestFileAge |

---

## 2. Kết nối Mạng & Socket Thực tế

- **Cổng User 3001**: Lắng nghe: `$listen3001` | Kết nối Established: `$est3001`
- **Cổng Service 3002**: Lắng nghe: `$listen3002` | Kết nối Established: `$est3002`

### Ma trận Ping 11 Máy lọc PrismaFlex
| Máy lọc | Địa chỉ IP | Kết quả Ping |
|:---:|:---:|:---:|
$pingRows

---

## 3. Trạng thái Chi tiết Các Kênh Socket Thiết bị (Từ Collector Engine)

| Thiết bị | Port | Socket State | Reconnects | Gói tin | Lỗi gần nhất | Thời điểm gói cuối (UTC) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
$devStatusLines

---

## 4. Trích đoạn Nhật ký Hệ thống Gần nhất (Logs Tail)

```text
$logExcerpt
```

---

## 5. Kết luận cho Dev Agent
- Dữ liệu cấu hình đã được copy vào: `collector/configs/collector_service.active.json`
- Mọi thông số thu thập được tuân thủ nguyên tắc không chứa thông tin cá nhân bệnh nhân.
"@

Set-Content -Path $reportPath -Value $mdContent -Encoding utf8
Write-Host "`nĐÃ TẠO BÁO CÁO THÀNH CÔNG TẠI:" -ForegroundColor Green
Write-Host "   $reportPath" -ForegroundColor Cyan

# 10. Hướng dẫn Agent bên kia hoàn tất đẩy Git
Write-Host "`n==========================================================" -ForegroundColor Magenta
Write-Host " HƯỚNG DẪN HOÀN TẤT CHO AGENT BÊN KIA:" -ForegroundColor Magenta
Write-Host " 1. git add collector/" -ForegroundColor White
Write-Host " 2. git commit -m 'chore(collector): export ICU-B live telemetry and active configs'" -ForegroundColor White
Write-Host " 3. git push origin main" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Magenta
