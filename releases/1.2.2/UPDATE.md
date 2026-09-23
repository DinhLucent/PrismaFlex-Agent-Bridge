# Bàn giao PrismaFlex 1.2.2 — cập nhật có kiểm tra tại máy đích

Ngày 23/09/2026. Bản này sửa cách chọn/hiển thị thời gian, hợp nhất dữ liệu chart và snapshot Treatment Journal. Đây là bản bàn giao để nghiệm thu tại máy đích; không coi kết quả test source là chứng nhận mọi kịch bản thực tế.

## Phạm vi và điều kiện

- Chỉ cập nhật WebPlatform. PostgreSQL, Collector và OIE không nằm trong ZIP.
- Gói dùng management protocol 2, database revision `d4b2a8f91c30`, cùng site và trust roots của bộ 1.2.1. Không cần migration khi bản cũ có đúng revision này.
- Không yêu cầu nối liền treatment đang chạy qua lần nâng cấp trong giai đoạn đầu. Vẫn giữ backup và dữ liệu cũ. Không tự đổi treatment thành COMPLETED/APPROVED, không xóa journal để làm cho kiểm tra pass.
- Updater hiện tại không triển khai chính sách chủ động tách ca khi update. Không coi bài test tự sửa trạng thái DB là hành vi của updater.
- Không chạy Collector thứ hai hoặc kết nối giả lập vào máy điều trị thật.

## 1. Nhận và kiểm tra gói

Tải ZIP và file `.sha256` từ GitHub Release được chỉ trong Agent-Bridge. So sánh SHA-256 rồi giải nén vào thư mục media riêng. Giữ nguyên toàn bộ thư mục `release`; không chép vài EXE đè bản cũ.

Agent ghi lại phiên bản đang cài, tên/path dịch vụ, DB revision, trạng thái license, dung lượng trống và khả năng giữ/retry backlog của OIE. Không ghi mật khẩu, license, raw payload hoặc mã bệnh nhân vào báo cáo gửi GitHub.

Ví dụ PowerShell Administrator, thay đường dẫn cho đúng máy đích:

```powershell
$installRoot = 'C:\PrismaFlex'
$package = 'D:\Media\PrismaFlex-1.2.2-windows-x64\release'
$statePath = Join-Path $installRoot 'shared\install-state.json'
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
$oldRelease = Join-Path $installRoot ("releases\{0}" -f $state.active_version)
$oldExe = Join-Path $oldRelease 'api\prismaflex.exe'
& $oldExe verify-release --directory $package --deployment
if ($LASTEXITCODE -ne 0) { throw 'Package verification failed; keep current installation' }
& $oldExe --install-root $installRoot license-status
if ($LASTEXITCODE -ne 0) { throw 'License check failed' }
& $oldExe --install-root $installRoot db-revision
if ($LASTEXITCODE -ne 0) { throw 'Database revision check failed' }
```

Đối chiếu revision trả về với `release.json`; site hash phải khớp, phiên bản đích lớn hơn bản cũ, install/update state không dở dang. Nếu không có install-state hoặc đang chạy từ source/demo: không chạy updater này. Lập phương án cài riêng với DB rỗng và backup trước; không sửa metadata để vượt kiểm tra. Hướng dẫn legacy trong media chỉ để tham khảo, ví dụ protocol 1/IP cố định của bản 1.1.2 không áp dụng nguyên xi cho protocol 2.

## 2. Cập nhật

Chọn cửa sổ bảo trì; giữ hàng đợi gửi theo quy trình thực tế của OIE. Kiểm tra backup có thể tạo được và đủ dung lượng. Dùng updater từ release cũ đã tin cậy:

```powershell
& (Join-Path $oldRelease 'deployment\update\Update-Release.ps1') `
    -InstallRoot $installRoot -PackageDir $package -MaintenanceConfirmed
if ($LASTEXITCODE -ne 0) { throw 'Inspect shared/update.json before further actions' }
```

Updater dừng services, backup database/runtime/config/license, chuyển phiên bản và kiểm tra readiness. Không bootstrap lại admin, không sửa config/license nếu không cần. Không tự cập nhật Collector/OIE trong bước này.

## 3. Nghiệm thu trước khi xác nhận hoàn tất

```powershell
$state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
$newExe = Join-Path $installRoot ("releases\{0}\api\prismaflex.exe" -f $state.active_version)
& $newExe --install-root $installRoot ready
if ($LASTEXITCODE -ne 0) { throw 'Readiness failed' }
& $newExe --install-root $installRoot license-status
if ($LASTEXITCODE -ne 0) { throw 'License failed after update' }
```

Phải có `active_version=1.2.2`, update phase `HEALTHY`, dịch vụ đúng thư mục và login hoạt động. Cho nguồn gửi tiếp tục, kiểm tra backlog thật được tiêu thụ.

| Kiểm tra | Điều kiện đạt |
|---|---|
| Thời gian card/chart | Một gói biết trước có cùng instant ở lịch sử và live; hiển thị giờ Việt Nam đúng, không cộng thêm 7 giờ. Phân biệt giờ nhận với giờ sự kiện máy. |
| Chart | Lịch sử + live không trùng điểm, thứ tự đúng; reconnect trở lại có dữ liệu; đổi ca không còn điểm ca trước; thử chuyển trang rồi quay lại. |
| Mất kết nối | Trên môi trường giả lập: 30 giây, 5 phút, 2 giờ rồi backlog; không tạo ca ma, gói lặp không nhân journal. |
| Đổi bệnh nhân | Cùng thiết bị, patient mới với RUN: kiểm tra ca cũ/ca mới và journal tách đúng. Thử ID rỗng/placeholder và gói cũ đến muộn. Dùng ID giả khi test. |
| Journal | H00, ranh giới giờ, OC đúng cột Set/Actual; vitals cũ quá 30 phút không tiếp tục dùng; ca đã duyệt không bị sửa. |
| Sau update có ca đang chạy | Có dữ liệu mới, chart/journal mới không kẹt; chấp nhận gián đoạn/không nối liền ca cũ. Nếu kẹt, báo lỗi; không tự duyệt hoặc xóa ca để bỏ qua. |

Không cố tình ngắt máy điều trị đang hoạt động để thử lỗi. Dùng simulator hoặc môi trường nghiệm thu tách biệt. Tải 100.000 gói và soak 60 phút được hoãn; đợt burst cũ có delivery latency vượt SLO, chưa chứng minh chịu tải lớn.

## 4. Khi thất bại

Giữ release cũ, backup và `shared\update.json`. Updater có thể tự rollback khi cùng schema; xác minh `ROLLED_BACK` và readiness bản cũ. Nếu operation còn FAILED, dùng `deployment\update\Rollback-Release.ps1` từ `$oldRelease` với `-InstallRoot $installRoot`, sau khi đọc trạng thái. Nếu migration đã bắt đầu, cần database phục hồi riêng/rỗng và `-RecoveryConfig`; không ép chạy code cũ trên schema mới.

Rollback script chỉ phục hồi operation thất bại, không phải lệnh downgrade tùy ý sau HEALTHY. Không gây lỗi update trên máy thật để thử rollback.

## 5. Báo cáo trả lại

Ghi phiên bản trước/sau, SHA ZIP, kết quả verify/ready/license, backup ID, trạng thái services, kết quả từng hàng nghiệm thu (PASS/FAIL/CHƯA CHẠY), lỗi và cách phục hồi. Ảnh/log phải ẩn định danh bệnh nhân và secrets. Đưa báo cáo đã khử định danh vào `PrismaFlex-Agent-Bridge/reports/`; không đưa DB dump hoặc runtime config lên GitHub.
