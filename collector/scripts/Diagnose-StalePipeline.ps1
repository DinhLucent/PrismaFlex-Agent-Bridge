<#
.SYNOPSIS
    Chẩn đoán toàn diện nguyên nhân hệ thống liên tục hiển thị STALE và không nhận dữ liệu.
.DESCRIPTION
    Quét từ đầu đến cuối 5 mắt xích của chuỗi truyền dẫn:
    [1] Máy lọc / Moxa -> Collector (Port 3001/3002)
    [2] Collector Outbox (ready\)
    [3] OIE Mirth Connect (oieservice & Channels)
    [4] WebPlatform Backend API (Cổng 8000 & /api/v1/telemetry/ingest)
    [5] WebPlatform Frontend / WebSocket (Cổng 3000)
#>

$ErrorActionPreference = "Continue"
$nowUtc = [DateTime]::UtcNow
$nowLocal = Get-Date

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host " [CHẨN ĐOÁN NGHẼN PIPELINE] TÌM NGUYÊN NHÂN HIỆN TƯỢNG STALE" -ForegroundColor Cyan
Write-Host " Thời gian kiểm tra: $($nowLocal.ToString('yyyy-MM-dd HH:mm:ss')) (GMT+7)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$issuesFound = @()

# -----------------------------------------------------------------
# BƯỚC 1: KIỂM TRA TẦNG THU NHẬN COLLECTOR (PORT 3001/3002)
# -----------------------------------------------------------------
Write-Host "`n>>> [1/5] KIỂM TRA DỊCH VỤ COLLECTOR & TẦNG MẠNG THIẾT BỊ..." -ForegroundColor Yellow
$statusPath = "C:\ProgramData\PrismaFlex\Collector\status\collector_status.json"
if (Test-Path $statusPath) {
    try {
        $statusJson = Get-Content -Path $statusPath -Raw -Encoding utf8 | ConvertFrom-Json
        $freshDevices = 0
        $staleDevices = @()
        
        foreach ($d in $statusJson.devices) {
            if ($d.state -eq "CONNECTED" -and $d.last_packet_at_utc) {
                $lastPktTime = [DateTime]::Parse($d.last_packet_at_utc).ToUniversalTime()
                $ageSec = [math]::Round(($nowUtc - $lastPktTime).TotalSeconds, 1)
                
                if ($ageSec -lt 30) {
                    $freshDevices++
                    Write-Host "   - PF_$(('{0:D3}' -f [int]$d.device_id)) (Port $($d.source_port)): LIVE (Packet cách đây $ageSec s)" -ForegroundColor Green
                } else {
                    $staleDevices += "PF_$(('{0:D3}' -f [int]$d.device_id)) (Port $($d.source_port), cách đây $ageSec s)"
                    Write-Host "   - PF_$(('{0:D3}' -f [int]$d.device_id)) (Port $($d.source_port)): STALE (Packet cách đây $ageSec s - TỪ $($lastPktTime.ToString('HH:mm:ss')) UTC)" -ForegroundColor Red
                }
            }
        }
        
        if ($staleDevices.Count -gt 0 -and $freshDevices -eq 0) {
            $issuesFound += "[ĐIỂM NGHẼN 1]: Collector không nhận được packet mới từ các máy lọc! Dữ liệu cuối cùng nhận được cách đây khá lâu. Kiểm tra cáp Serial Moxa hoặc luồng dữ liệu từ máy lọc."
        }
    } catch {
        Write-Warning "Không đọc được collector_status.json: $_"
    }
} else {
    $issuesFound += "[ĐIỂM NGHẼN 1]: Không tìm thấy collector_status.json! PrismaFlexCollectorService có thể chưa chạy."
}

# -----------------------------------------------------------------
# BƯỚC 2: KIỂM TRA HÀNG ĐỢI OUTBOX READY (COLLECTOR -> MIRTH)
# -----------------------------------------------------------------
Write-Host "`n>>> [2/5] KIỂM TRA HÀNG ĐỢI OUTBOX (ready\)..." -ForegroundColor Yellow
$readyDir = "C:\ProgramData\PrismaFlex\Collector\outbox\ready"
if (Test-Path $readyDir) {
    $readyFiles = Get-ChildItem -Path $readyDir -Filter "*.json" -ErrorAction SilentlyContinue
    $count = $readyFiles.Count
    if ($count -gt 20) {
        Write-Host "   - Hàng đợi outbox\ready có $count files TỒN ĐỌNG!" -ForegroundColor Red
        $issuesFound += "[ĐIỂM NGHẼN 2]: Hàng đợi outbox\ready bị ứ đọng ($count files). Dịch vụ OIE Mirth Connect (oieservice) có thể bị treo hoặc không đọc file!"
    } elseif ($count -gt 0) {
        Write-Host "   - Hàng đợi outbox\ready đang luân chuyển: $count files đang chờ xử lý." -ForegroundColor Green
    } else {
        Write-Host "   - Hàng đợi outbox\ready: 0 files tồn đọng (Sạch)." -ForegroundColor Yellow
    }
}

# -----------------------------------------------------------------
# BƯỚC 3: KIỂM TRA DỊCH VỤ MIRTH CONNECT (OIESERVICE)
# -----------------------------------------------------------------
Write-Host "`n>>> [3/5] KIỂM TRA DỊCH VỤ OIE MIRTH CONNECT..." -ForegroundColor Yellow
$oieSvc = Get-Service -Name "oieservice" -ErrorAction SilentlyContinue
if ($oieSvc) {
    if ($oieSvc.Status -eq "Running") {
        Write-Host "   - Dịch vụ oieservice: RUNNING" -ForegroundColor Green
    } else {
        Write-Host "   - Dịch vụ oieservice: $($oieSvc.Status)" -ForegroundColor Red
        $issuesFound += "[ĐIỂM NGHẼN 3]: Dịch vụ oieservice KHÔNG chạy ($($oieSvc.Status))! Mirth không thể giải mã và đẩy dữ liệu sang WebPlatform."
    }
} else {
    Write-Warning "Không tìm thấy service oieservice."
}

# -----------------------------------------------------------------
# BƯỚC 4: KIỂM TRA BACKEND API (CỔNG 8000) & ENDPOINT INGEST
# -----------------------------------------------------------------
Write-Host "`n>>> [4/5] KIỂM TRA BACKEND WEBPLATFORM API (CỔNG 8000)..." -ForegroundColor Yellow
$apiSvc = Get-Service -Name "prismaflex-api" -ErrorAction SilentlyContinue
if ($apiSvc) {
    Write-Host "   - Dịch vụ prismaflex-api: $($apiSvc.Status)" -ForegroundColor $(if ($apiSvc.Status -eq 'Running') { 'Green' } else { 'Red' })
}

# Test HTTP Port 8000
try {
    $healthResp = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/health" -Method Get -TimeoutSec 3 -ErrorAction Stop
    Write-Host "   - API Health Check (http://127.0.0.1:8000/api/v1/health): OK" -ForegroundColor Green
} catch {
    Write-Host "   - API Health Check cổng 8000 THẤT BẠI: $_" -ForegroundColor Red
    $issuesFound += "[ĐIỂM NGHẼN 4]: Backend API (cổng 8000) không phản hồi! Mirth Connect không thể POST dữ liệu vào API."
}

# Kiểm tra bản ghi Telemetry Receipt mới nhất
try {
    $receiptsResp = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/v1/telemetry/receipts/latest" -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($receiptsResp -and $receiptsResp.received_at_utc) {
        $lastReceiptUtc = [DateTime]::Parse($receiptsResp.received_at_utc).ToUniversalTime()
        $receiptAgeSec = [math]::Round(($nowUtc - $lastReceiptUtc).TotalSeconds, 1)
        Write-Host "   - Telemetry Receipt mới nhất trên API: cách đây $receiptAgeSec s ($($lastReceiptUtc.ToString('HH:mm:ss')) UTC)" -ForegroundColor $(if ($receiptAgeSec -lt 30) { 'Green' } else { 'Red' })
        if ($receiptAgeSec -gt 30) {
            $issuesFound += "[ĐIỂM NGHẼN 4B]: API cổng 8000 không nhận được Telemetry Receipt mới trong $receiptAgeSec giây qua! (Lần cuối: $($lastReceiptUtc.ToString('HH:mm:ss')) UTC)"
        }
    }
} catch {
    # Endpoint có thể khác hoặc cần auth
}

# -----------------------------------------------------------------
# BƯỚC 5: KIỂM TRA FRONTEND WEB (CỔNG 3000) & WEBSOCKET
# -----------------------------------------------------------------
Write-Host "`n>>> [5/5] KIỂM TRA GIAO DIỆN WEB (CỔNG 3000)..." -ForegroundColor Yellow
$webSvc = Get-Service -Name "prismaflex-web" -ErrorAction SilentlyContinue
if ($webSvc) {
    Write-Host "   - Dịch vụ prismaflex-web: $($webSvc.Status)" -ForegroundColor $(if ($webSvc.Status -eq 'Running') { 'Green' } else { 'Red' })
}

$conn3000 = Get-NetTCPConnection -LocalPort 3000 -State Listen -ErrorAction SilentlyContinue
if ($conn3000) {
    Write-Host "   - Cổng 3000 (Web Frontend): Đang lắng nghe (PID: $($conn3000.OwningProcess | Select-Object -Unique))" -ForegroundColor Green
} else {
    Write-Host "   - Cổng 3000: KHÔNG LẮNG NGHE!" -ForegroundColor Red
    $issuesFound += "[ĐIỂM NGHẼN 5]: Cổng 3000 không hoạt động."
}

# -----------------------------------------------------------------
# KẾT LUẬN & HƯỚNG DẪN XỬ LÝ
# -----------------------------------------------------------------
Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host " KẾT QUẢ PHÂN TÍCH ĐIỂM NGHẼN GÂY HIỆN TƯỢNG STALE:" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

if ($issuesFound.Count -eq 0) {
    Write-Host "Tất cả các tầng đều phản hồi bình thường! Nếu UI vẫn hiện STALE, kiểm tra độ lệch đồng hồ giữa máy tính và máy lọc (Timezone Drift)." -ForegroundColor Green
} else {
    foreach ($iss in $issuesFound) {
        Write-Host "$iss" -ForegroundColor Red
    }
}
Write-Host "`n================================================================" -ForegroundColor Cyan
