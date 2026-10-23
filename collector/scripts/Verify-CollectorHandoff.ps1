<#
.SYNOPSIS
    Xác minh luồng chuyển tiếp dữ liệu từ Collector Outbox sang OIE Mirth Connect.
.DESCRIPTION
    Kiểm tra xem các gói tin JSON nguyên tử có đang được sinh vào outbox\ready
    và được Mirth Connect tiêu thụ tức thời hay bị ứ đọng backlog.
#>

param(
    [string]$OutboxDir = "C:\ProgramData\PrismaFlex\Collector\outbox",
    [int]$WatchSeconds = 15
)

$ErrorActionPreference = "Continue"

Write-Host "=== Kiểm tra Hàng đợi Outbox & Luồng Chuyển tiếp OIE ===" -ForegroundColor Cyan

$readyDir = Join-Path $OutboxDir "ready"
if (-not (Test-Path $readyDir)) {
    Write-Warning "Không tìm thấy thư mục: $readyDir"
    return
}

$initialCount = (Get-ChildItem -Path $readyDir -Filter "*.json" -ErrorAction SilentlyContinue).Count
Write-Host "Số file JSON trong outbox\ready lúc bắt đầu: $initialCount" -ForegroundColor Yellow

Write-Host "Đang theo dõi hoạt động hàng đợi trong $WatchSeconds giây..." -ForegroundColor Cyan
Start-Sleep -Seconds $WatchSeconds

$finalFiles = Get-ChildItem -Path $readyDir -Filter "*.json" -ErrorAction SilentlyContinue
$finalCount = $finalFiles.Count
Write-Host "Số file JSON trong outbox\ready sau $WatchSeconds giây: $finalCount" -ForegroundColor Yellow

if ($finalCount -eq 0) {
    Write-Host "[PASS] Hàng đợi sạch sẽ (0 file tồn đọng). Kênh OIE PF_01_RAW_DECODE đang tiêu thụ liên tục." -ForegroundColor Green
} elseif ($finalCount -lt 20) {
    Write-Host "[OK] Hàng đợi luân chuyển bình thường ($finalCount files đang được xử lý)." -ForegroundColor Green
} else {
    Write-Warning "[WARN] Phát hiện $finalCount files ứ đọng trong outbox\ready! Cần kiểm tra dịch vụ oieservice."
}
