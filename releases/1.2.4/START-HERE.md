# ICU-B — cập nhật PrismaFlex 1.2.1 lên 1.2.4

Đây là hướng dẫn cho **máy ICU-B tại `C:\PrismaFlex`**, cài theo management protocol 2. Đọc [prompt cho agent](PROMPT-ICU-B-AGENT.md), [ghi chú phát hành](RELEASE-NOTES.md) và [mẫu nghiệm thu](TARGET-REPORT.md) trước khi làm. [Gói Windows x64 đã ký](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/releases/tag/v1.2.4-pilot) có SHA-256 trong `ARTIFACT.json`. Không dùng source ZIP tự sinh của GitHub.

**Mục tiêu bắt buộc:** treatment đang `IN_PROGRESS` phải giữ cùng ID, thời điểm bắt đầu và journal; dữ liệu trong thời gian Web/API tạm dừng phải được Collector/OIE lưu bền và gửi bù sau khi API hoạt động. Chưa chứng minh được hàng đợi và `delivery_id` ổn định thì **chưa bắt đầu update**. Không dừng máy lọc hoặc tạo Collector thứ hai để thử.

## 1. Nhận và kiểm tra gói

Mở PowerShell **Run as Administrator** ở clone Agent Bridge; `git pull --ff-only`. Chọn thư mục media chưa tồn tại:

```powershell
$guide = Join-Path $PWD 'releases\1.2.4'
$installRoot = 'C:\PrismaFlex'
& (Join-Path $guide 'Receive-Package.ps1') -Destination 'D:\PrismaFlexMedia\1.2.4'
if ($LASTEXITCODE -ne 0) { throw 'Download or SHA-256 verification failed' }
$package = 'D:\PrismaFlexMedia\1.2.4\expanded\PrismaFlex-1.2.4-windows-x64\release'
& (Join-Path $guide 'Inspect-Target.ps1') -InstallRoot $installRoot -PackageDir $package `
  -Phase Before -ReportPath (Join-Path $env:TEMP 'prismaflex-124-before.json')
if ($LASTEXITCODE -ne 0) { throw 'Preflight blocked; keep 1.2.1 running' }
```

`Receive-Package.ps1` chỉ giải nén sau khi kích thước và SHA-256 ZIP khớp. Nếu dùng USB, truyền `-ArchivePath` là ZIP gốc, không tái nén. `Inspect-Target` dùng chính verifier đã cài ở 1.2.1 để kiểm chữ ký 1.2.4, site, feature, license, DB revision, services và các endpoint. Báo cáo lỗi chỉ có trạng thái; xem chi tiết tại máy đích, không đẩy config/log thô lên GitHub. Nếu thư mục media hoặc file báo cáo đã có, chọn tên mới; không ghi đè.

Preflight dự kiến: active `1.2.1`, phase `READY`, DB revision `d4b2a8f91c30`, Web 3000/API 8000/Analyzer 15555; kiểm tra thực tế, không ép thay đổi để khớp giả định. `pg_dump.exe`/`pg_restore.exe` PostgreSQL 16 phải sẵn. Đo dung lượng trống đủ cho ZIP, release mới, bản sao `shared\var` và dump DB thật; mức 2 GB trong script chỉ là sàn tối thiểu. Kiểm tra đồng hồ Windows, giờ nguồn thiết bị và giờ hiển thị như ba phép đo khác nhau.

## 2. Chốt cổng an toàn cho treatment đang chạy

Trước khi chạy updater, lưu **cục bộ, bảo mật** danh sách treatment `IN_PROGRESS`: ID, thiết bị, start time, số raw/receipt, mốc journal cuối. Lưu số backlog và `delivery_id` mẫu đã khử định danh. Xác minh Collector/OIE hiện chạy một bản duy nhất, tiếp tục thu và ghi vào hàng đợi bền vững khi API không có, retry giữ nguyên `delivery_id`, rồi receipt được xử lý sau kết nối lại. Dùng bằng chứng cấu hình/log và thử trên simulator hoặc môi trường cách ly; không gây mất kết nối máy điều trị thật. Nếu không chứng minh được, dừng tại đây và báo điều kiện còn thiếu.

Kiểm tra backup riêng: quyền và công cụ dump DB, không gian đĩa, khả năng restore trên môi trường tách biệt. Thông báo cửa sổ gián đoạn giao diện 10–15 phút **là dự tính**, không phải cam kết; thời gian backup phụ thuộc dữ liệu thật. Collector/gateway 3001/3002 là luồng riêng. Không thêm default gateway vào NIC `192.168.5.1/24` chỉ vì đang để trống; các IP cùng subnet đi trực tiếp. Kiểm tra firewall theo profile/port nếu thực sự chặn.

## 3. Nâng cấp bằng updater của bản cũ

Updater 1.2.1 là công cụ bắt buộc cho lần chuyển đầu; nó dừng Web/API/Analyzer, sao lưu DB, `shared\var`, config/license, chuyển release và khởi động lại. Nó không thay Collector/OIE. Giữ nguồn gửi ở chế độ queue/retry đã xác minh.

```powershell
$state = Get-Content -LiteralPath (Join-Path $installRoot 'shared\install-state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$oldRelease = Join-Path $installRoot ("releases\{0}" -f $state.active_version)
& (Join-Path $oldRelease 'deployment\update\Update-Release.ps1') `
  -InstallRoot $installRoot -PackageDir $package -MaintenanceConfirmed
if ($LASTEXITCODE -ne 0) { throw 'Update failed; inspect update.json and use recovery procedure below' }
```

Không xóa release cũ, `shared\var`, backup hoặc dữ liệu ca. Không chạy `migrate` thủ công khi revision không đổi. Không sửa `COMPLETED`/`APPROVED` hay xóa journal để làm nghiệm thu đạt.

**Bước riêng cho lần đầu từ 1.2.1:** updater cũ sẽ ghi lại WinSW XML theo mẫu cũ. Sau khi update báo `READY/HEALTHY`, áp dụng dependency bằng module nằm trong **release mới đã ký**; script kiểm chữ ký và ownership trước khi sửa XML/SCM:

```powershell
& (Join-Path $guide 'Apply-Startup-Dependencies.ps1') -InstallRoot $installRoot
if ($LASTEXITCODE -ne 0) { throw 'Startup dependencies not applied; do not reboot' }
& (Join-Path $guide 'Inspect-Target.ps1') -InstallRoot $installRoot -PackageDir $package `
  -Phase After -ReportPath (Join-Path $env:TEMP 'prismaflex-124-after.json')
if ($LASTEXITCODE -ne 0) { throw 'Postflight blocked; do not claim completion' }
```

Ba service phải có `winmgmt`; API và Analyzer thêm `postgresql-x64-16` khi dùng PostgreSQL cục bộ; Web thêm `prismaflex-api`. Kiểm tra cả SCM lẫn WinSW XML. Đã thấy máy ICU-B từng được chỉnh SCM thủ công, nhưng báo cáo chưa chứng minh reboot **sau** lần chỉnh đó. Không reboot để thử trong khi đang ghi treatment nếu chưa xác nhận queue và cửa sổ bảo trì; khi thử reboot sau đó, kiểm tra lại dịch vụ, cổng 3000, gateway 3001/3002, backlog và receipt.

## 4. Nghiệm thu thật

Đối chiếu `active_version=1.2.4`, `install-state.phase=READY`, `update.phase=HEALTHY`, backup ID có dump khác rỗng và `backup.json`. Web `/login` trên máy chủ và một máy trạm LAN trả trang, tải JS/CSS, đăng nhập và WebSocket hoạt động. Mở monitor để chắc logo không tạo cache ảnh ngoài manifest; chạy lại `verify-release` sau khi mở trang. Thời gian card, chart, tooltip, Machine Time hiển thị theo giờ Việt Nam; phân biệt với giờ nhận gói và đồng hồ vật lý.

Đợi backlog giảm, receipt được xử lý, rồi so **từng ID treatment đã chụp trước update**: cùng ID/start time, còn `IN_PROGRESS` nếu không có sự kiện kết thúc thật; raw/receipt mới và journal tiếp tục theo lịch snapshot. Kiểm tra cả trường hợp có và không có gói gửi bù. HTTP 200 đơn thuần chưa chứng minh data vào journal. Journal không còn nút Analysis; trang Analyzer độc lập vẫn hoạt động. Không ép tạo H00/H01 trước điều kiện snapshot. Nếu ca bị tách, dữ liệu thiếu hoặc journal kẹt, ghi FAIL và giữ bằng chứng đã khử định danh.

## 5. Khi lỗi

Nếu preflight không đạt, giữ 1.2.1 và không chạy updater. Nếu updater báo `ROLLED_BACK`, xác minh 1.2.1 READY/login/ingest rồi báo thất bại. Nếu `FAILED`, giữ backup và đọc `shared\update.json`; dùng **recovery của bản cũ** theo trạng thái. Chỉ rollback an toàn khi `migration_started=false`; nếu true, cần quy trình restore DB riêng. Không chạy updater lần hai chồng lên lần lỗi, không sửa `update.json` để vượt chặn. Nếu đã `HEALTHY` mà nghiệm thu dữ liệu không đạt, không dùng rollback như lệnh downgrade tùy ý: bảo toàn DB/backup/queue và chẩn đoán. Tài liệu recovery chi tiết của protocol 2: [bản 1.2.3](../1.2.3/START-HERE.md#5-nếu-có-lỗi).

Hoàn tất [mẫu báo cáo](TARGET-REPORT.md) bằng PASS/FAIL/CHƯA CHẠY, không đưa thông tin bệnh nhân, fingerprint, license, mật khẩu, runtime config hoặc raw data lên GitHub.
