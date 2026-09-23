# Agent máy đích — bắt đầu ở đây, PrismaFlex 1.2.3

**Dùng 1.2.3 thay cho 1.2.2.** Review mở rộng phát hiện trục/tooltip chart và một số giờ trên trang monitor còn dùng timezone trình duyệt. 1.2.3 sửa thống nhất giờ Việt Nam; không đổi schema hoặc thuật toán treatment so với 1.2.2.

[Bộ cài đã ký](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/releases/tag/v1.2.3-pilot) · [Báo cáo kiểm chứng](REVIEW.md) · [Cài mới](FRESH-INSTALL.md) · [Mẫu báo cáo](TARGET-REPORT.md)

Máy đích từng báo cài **1.2.1 tại C:\PrismaFlex**, DB revision `d4b2a8f91c30`, Web 3000/API 8000/Analyzer 15555. Đây là dữ liệu báo cáo ngày 15/09, phải kiểm tra lại, không coi là cấu hình hiện tại chắc chắn đúng.

## 1. Nhận gói

Tại thư mục clone `PrismaFlex-Agent-Bridge`, chạy `git pull --ff-only`, rồi:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\releases\1.2.3\Receive-Package.ps1 `
  -Destination 'D:\PrismaFlexMedia\1.2.3'
```

Script dùng PowerShell có sẵn, không cần GitHub CLI/Python/Node. Tải ZIP từ URL cố định, kiểm tra hash từ `ARTIFACT.json`, chỉ giải nén vào thư mục mới. Nếu máy không có Internet, chép ZIP từ máy build cùng bộ hướng dẫn này; tham số `-ArchivePath` nhận ZIP local. Không sửa release hoặc dùng source ZIP do GitHub tự tạo.

```powershell
$installRoot = 'C:\PrismaFlex'
$package = 'D:\PrismaFlexMedia\1.2.3\expanded\PrismaFlex-1.2.3-windows-x64\release'
$guide = Join-Path $PWD 'releases\1.2.3'
```

Các lệnh tiếp theo dùng PowerShell **Run as Administrator**. `-ExecutionPolicy Bypass` chỉ áp dụng tiến trình chạy script này; không đổi chính sách toàn máy.

## 2. Kiểm tra trước cập nhật

```powershell
& (Join-Path $guide 'Inspect-Target.ps1') -InstallRoot $installRoot -PackageDir $package `
  -Phase Before -ReportPath (Join-Path $env:TEMP 'prismaflex-123-before.json')
if ($LASTEXITCODE -ne 0) { throw 'Preflight blocked; inspect failed checks locally' }
```

Dùng tên report mới nếu file đã có. Script chỉ kiểm tra, không dừng dịch vụ/cài phần mềm. PASS bao gồm chữ ký bản cũ và mới, version/site/features, license, revision, trạng thái update, vị trí và trạng thái services, API workers, trang login, Analyzer và sự tồn tại công cụ backup. PASS không thay kiểm tra login, dung lượng backup thực tế hoặc kiểm tra lâm sàng.

Trước khi chạy updater, agent còn phải:

1. Xác nhận đúng máy/đúng thư mục dịch vụ. Không chạy Collector thứ hai; không giả lập gói trên thiết bị điều trị thật.
2. Ghi cổng hiện dùng bằng cách đọc **chọn trường** `PORT, WEB_PORT, ANALYZER_PORT` trong runtime config; không in cả file có mật khẩu.
3. Kiểm tra `install-state.pg_bin` chứa `pg_dump.exe`, `pg_restore.exe` đúng PostgreSQL 16. Tài khoản DB hiện tại cần tạo dump được; updater sẽ xác minh dump. Không thay URL database khi update.
4. Dự trù chỗ trống cho bản release mới + bản sao `shared\var` + DB dump + media tải về. Ngưỡng 2 GB trong script chỉ là kiểm tra tối thiểu; DB lớn có thể cần nhiều hơn. Không xóa dữ liệu để lấy chỗ trống.
5. Chốt cửa sổ bảo trì và OIE giữ/retry delivery khi API tạm dừng. Kiểm tra hàng đợi persistent; giữ `delivery_id` khi gửi lại. Không giả định HTTP 200 nghĩa là đã ghi journal. Không tự dừng Collector nếu chưa xác minh outbox/queue giữ gói đúng.
6. Chụp số lượng backlog, số thiết bị đang RUN và giờ cuối nhận; chỉ báo cáo số tổng, không chụp định danh bệnh nhân.

Nếu có bản cài source/demo, protocol 1, thiếu state hoặc khác feature/site: không đi đường update tự động này. Xem [cài mới](FRESH-INSTALL.md); giữ bản cũ/backup và báo khác biệt.

## 3. Cập nhật bằng updater cũ

```powershell
$state = Get-Content -LiteralPath (Join-Path $installRoot 'shared\install-state.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$oldVersion = $state.active_version
$oldRelease = Join-Path $installRoot ("releases\{0}" -f $oldVersion)
& (Join-Path $oldRelease 'deployment\update\Update-Release.ps1') `
  -InstallRoot $installRoot -PackageDir $package -MaintenanceConfirmed
if ($LASTEXITCODE -ne 0) { throw 'Update failed; follow recovery table below' }
```

Giữ `$oldRelease` để phục hồi. Updater tạo backup DB/runtime/config/license trong `shared\backups\<backup_id>`. Không bootstrap admin, không sửa activation hoặc thay Collector/OIE. Bản 1.2.3 dùng revision `d4b2a8f91c30`, nên không chạy migration khi bản cũ có cùng revision.

## 4. Xác nhận kết quả

```powershell
& (Join-Path $guide 'Inspect-Target.ps1') -InstallRoot $installRoot -PackageDir $package `
  -Phase After -ReportPath (Join-Path $env:TEMP 'prismaflex-123-after.json')
if ($LASTEXITCODE -ne 0) { throw 'Postflight failed; do not report update complete' }
```

Sau đó khôi phục nguồn gửi theo quy trình OIE đã chuẩn bị, và kiểm tra:

- Đăng nhập bằng tài khoản đang có trên máy chủ và một máy trạm LAN. Web tải được JS/CSS, WebSocket kết nối; F5 hoặc đóng/mở tab để bỏ bundle cũ.
- `active_version=1.2.3`, `install-state.phase=READY`, `update.phase=HEALTHY`; backup ID tồn tại, dump khác rỗng và có `backup.json`.
- Gói LIVE mới cập nhật thiết bị, card, chart và journal. So giờ sự kiện canonical với điểm chart; giờ nhận trên card có thể khác giờ máy. Cả hai hiển thị Việt Nam, không cộng thêm 7 giờ.
- Backlog giảm về mức bình thường, receipt được xử lý; không chỉ nhìn HTTP ACK. Dữ liệu ca cũ không lẫn ca mới.
- Journal có H00/giờ/OC đúng khi đến điều kiện; phân biệt Set/Actual, vitals cũ quá 30 phút không được giữ vô hạn. Không ép tạo H00 ngay nếu chưa đến điều kiện snapshot.
- Nghiệm thu reconnect/đổi bệnh nhân/gói cũ đến muộn trên simulator hoặc môi trường test. Không ngắt máy điều trị thật để thử.

Giai đoạn đầu chấp nhận ca đang chạy không nối liền qua update. Vẫn giữ backup và ca cũ; **không tự gán COMPLETED/APPROVED, không xóa treatment/journal để làm kiểm tra pass**. Updater không có chức năng chủ động tách ca. Nếu nhận dữ liệu mới mà journal kẹt: giữ bằng chứng đã khử định danh và báo lỗi.

## 5. Nếu có lỗi

| Trạng thái | Cách xử lý |
|---|---|
| Hash/signature/site/license/revision không đạt | Giữ bản cũ, kiểm tra đúng package và install root. Không bỏ verifier hoặc sửa metadata. License không hợp lệ cần owner xử lý, không thể tự sinh ở máy đích. |
| STOPPED/FAILED, backup lỗi hoặc thiếu pg tools | Giữ nguồn gửi ở trạng thái bảo trì, kiểm tra dịch vụ và log local. Chưa có backup thì không được xóa runtime/DB. Dùng recovery cũ theo trạng thái, không chạy lại updater chồng lên. |
| ROLLED_BACK | Xác minh bản cũ ready và login/ingest hoạt động, rồi cho nguồn gửi tiếp tục. Báo update thất bại dù hệ thống cũ đã chạy lại. |
| FAILED và migration_started=false | Dùng script recovery cũ bên dưới. Nó kiểm tra schema trước khi khởi động lại code cũ. |
| migration_started=true | Cần DB phục hồi riêng/rỗng, file UTF-8 chỉ định `POSTGRES_URL`, và `-RecoveryConfig`; không ép code cũ chạy với schema mới. 1.2.1→1.2.3 bình thường không vào nhánh này. |
| HEALTHY nhưng UI/ingest không đúng | Không dùng rollback script như lệnh downgrade tùy ý. Giữ backup, ghi nhận lỗi, kiểm tra cache/cổng/WebSocket/OIE. Chọn phương án phục hồi riêng nếu cần. |
| Thư mục releases\1.2.3 đã tồn tại sau lần lỗi | Không ghi đè/xóa. Chỉ cách ly thư mục candidate sau khi chứng minh bản cũ đang active/ready, không service nào tham chiếu candidate và operation đã được phục hồi. Nếu chưa chắc, dừng ở đây và báo tình trạng. |

```powershell
& (Join-Path $oldRelease 'deployment\update\Rollback-Release.ps1') -InstallRoot $installRoot
if ($LASTEXITCODE -ne 0) { throw 'Recovery needs local diagnosis; preserve backup and state' }
```

Sau recovery luôn đọc lại state, kiểm tra ready/login/ingest trước khi gửi dữ liệu tiếp. Không chỉnh `update.json` bằng tay để bỏ trạng thái bảo trì. Log local có thể chứa dữ liệu nhạy cảm: chỉ gửi phần đã khử định danh.

## 6. Hoàn tất bàn giao

Điền [TARGET-REPORT.md](TARGET-REPORT.md), lưu bản kết quả trong `reports/` và push riêng file đó. Mỗi mục ghi PASS/FAIL/CHƯA CHẠY. Không đẩy raw, DB dump, runtime config, license hoặc ảnh có mã bệnh nhân lên GitHub. Chưa chứng minh tải 100.000 gói/soak 60 phút; không mô tả là đã nghiệm thu tải lớn.
