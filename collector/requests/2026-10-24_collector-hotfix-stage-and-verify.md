# COL-HF-20261024-01 — Chẩn đoán, chuẩn bị và kiểm chứng hotfix Collector

- **Ngày**: 2026-10-24
- **Người gửi / nhận**: Dev Agent → Target Agent ICU-B
- **Ưu tiên**: P0 cho chẩn đoán STALE; candidate triển khai có kiểm soát
- **Cửa sổ bảo trì**: Bắt buộc cho thay EXE hoặc restart; thu baseline là chỉ đọc
- **Build**: `collector-hf-20261024.1`, nguồn Collector
  [`3c7811ada5f95b4978ce04c8f56a26242fc65c67`](https://github.com/DinhLucent/prismaflex-collector-v2/commit/3c7811ada5f95b4978ce04c8f56a26242fc65c67)
- **Tài liệu**: [bảng nâng cấp](../reports/2026-10-24_collector-hotfix-upgrade-matrix.md),
  [gói và rollback](../patches/2026-10-24_collector-hf-20261024.1-INSTRUCTIONS.md)

## 1. Mục tiêu

Xác định vì sao port 3002 có thể `CONNECTED` mà nguồn được chọn vẫn là
`User fallback`, đo thời gian/progress của writer và xác minh tính liên tục
raw/outbox. Tập trung vào bằng chứng theo **cùng thời điểm**. Không mặc định
SQLite, NTFS, GIL hoặc Service socket là nguyên nhân chỉ từ ảnh trạng thái.
`STALE` nghĩa là bản trạng thái không còn mới và phải coi là lỗi giám sát/thu
thập cho đến khi đối chiếu packet, DB và tiến trình. TCP `CONNECTED` không
chứng minh packet Service hợp lệ đi vào Collector.

## 2. Bước A — thu bằng chứng trước khi can thiệp (chỉ đọc)

1. `git pull --ff-only` trong Bridge. Xác nhận Git HEAD và ngày/giờ UTC/NTP
   của máy. Không chạy một Collector thứ hai, không mở/đổi DB hoặc xóa WAL.
2. Đọc cấu hình đang materialized **tại máy** để xác định chính xác status,
   runtime và outbox root; không commit cấu hình/secret. Với vị trí cài mặc
   định, chạy từ thư mục Bridge:

   ```powershell
   .\collector\scripts\Get-CollectorHotfixEvidence.ps1 `
     -StatusPath 'C:\ProgramData\PrismaFlex\Collector\status\collector_status.json' `
     -RuntimeDir 'C:\ProgramData\PrismaFlex\Collector\runtime' `
     -OutboxDir 'C:\ProgramData\PrismaFlex\Collector\outbox' `
     -OutputPath '.\collector\reports\2026-10-24_collector-hf-baseline-target.json'
   ```

   Script lấy 7 mẫu cách 10 giây, cho phép đối chiếu `status_sequence`,
   `generated_at_utc`, `writer_progress`, queue, packet mỗi port và stream.
   Nếu đường dẫn thực tế khác, thay tham số bằng đường dẫn đã xác minh.
3. Ghi riêng mốc UTC của GUI STALE, PID/SCM, bytes/packet tăng hay đứng,
   các port TCP do PID Collector sở hữu, lỗi/reconnect mỗi máy, tuổi packet
   Service và User, dung lượng DB/WAL/SHM, outbox ready và ổ đĩa. Với các máy
   đang có tín hiệu, tính **delta qua 60 giây** cho cả 3001 và 3002. Không
   tính một status JSON cũ thành số liệu hiện tại.
4. Dựa trên số liệu: nếu Service `CONNECTED` nhưng delta packet 3002 = 0,
   kiểm tra nguồn/Moxa/khung lỗi và `SILENT_CONNECTION_TIMEOUT`; nếu delta
   Service tăng liên tục nhưng vẫn User sau thời gian recovery + hold-down,
   ghi đủ timestamps/counters để điều tra FSM. Nếu cả hai port đứng và
   `writer_progress.current_command` giữ >30 giây hoặc status STALE, phân
   biệt writer/storage với nguồn máy; thu Windows Event log/LiveKernelEvent
   cùng mốc giờ (mã lỗi, không dump chứa dữ liệu bệnh nhân lên Git).
5. Gửi báo cáo `collector/reports/2026-10-24_collector-hf-baseline-target.md`
   nêu giả thuyết theo chứng cứ, các khoảng trống chưa đo được và mức độ ca
   lọc đang hoạt động (chỉ số lượng, không Patient ID). Giữ evidence JSON
   de-identified trong `collector/reports/`, kiểm tra thủ công trước khi push.

## 3. Bước B — xác minh gói và chuẩn bị cutover

1. Tải archive từ [prerelease](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/releases/tag/collector-hf-20261024.1).
   Đối chiếu SHA-256 archive, từng EXE và `manifest.json` theo
   [hướng dẫn hotfix](../patches/2026-10-24_collector-hf-20261024.1-INSTRUCTIONS.md).
   Nếu một hash sai, dừng. Xác nhận source commit, `build_id` và rằng đây là
   dịch vụ v2; không áp dụng cho legacy/watchdog/decoder.
2. Xác định đường dẫn cài thật bằng `Get-CimInstance Win32_Service` trường
   `PathName`; kiểm tra PID executable, bản quyền, config và dung lượng trống.
   Chừa chỗ cho bản sao nhất quán của DB+WAL+SHM, outbox và hai EXE cũ. Đo
   thời gian mở/index trên bản sao DB offline nếu có môi trường cô lập. Không
   chạy thử candidate cùng lúc với collector production.
3. Lập kế hoạch thời gian dừng, quyền thao tác và rollback với người quản trị
   hiện trường. Khi có ca `RECORDING/IN_PROGRESS`, chỉ cắt chuyển theo kế
   hoạch bảo toàn luồng dữ liệu đã được chấp thuận tại hiện trường. Nếu chưa
   có kế hoạch/cửa sổ, **chỉ staging**, ghi `CUTOVER_DEFERRED` và lý do;
   tiếp tục theo dõi và báo cáo bằng chứng, không tự restart/force-kill.
4. Trước Bước C, hoàn thành và đính kèm báo cáo **PASS** cho packaged soak 72
   giờ trong môi trường thử cô lập, reboot/logout/forced-kill và replay, field
   capacity preflight, cùng rollback rehearsal. So sánh packet identity/hash,
   sequence, outbox delivery và giới hạn tài nguyên; nếu bất kỳ gate nào
   `FAIL` hoặc `NOT_EXECUTED`, tiếp tục staging/chẩn đoán, **chưa cutover**.

## 4. Bước C — cutover có kiểm soát

1. Thu một snapshot cuối. Dừng service hiện hữu qua SCM; xác nhận process,
   socket và quyền sở hữu DB/WAL đã kết thúc. Nếu stop kẹt, lưu PID, wait
   reason/dump và báo quản trị; không chạy candidate hoặc xóa file để ép mở.
2. Lúc service đã dừng, sao lưu EXE cũ và **cùng một snapshot nhất quán**
   DB, WAL, SHM, config, license, outbox ready. Backup chỉ nằm trên hệ thống
   bảo vệ tại chỗ; không đưa lên Git. Ghi vị trí, hash và giờ backup trong
   báo cáo nhưng không ghi nội dung nhạy cảm.
3. Thay hai EXE đã kiểm hash vào đúng thư mục hiện hành. Khởi động **duy nhất**
   `PrismaFlexCollectorService`. Nếu startup vượt thời gian hợp lý hoặc trả
   lỗi index/disk/license, ngừng cutover và theo rollback.
4. Trong 10 phút đầu, thu thêm 7 mẫu bằng script với output khác
   `collector/reports/2026-10-24_collector-hf-after-target.json`. So sánh
   baseline và post-cutover: SCM RUNNING, `build_id` đúng, instance ID mới,
   status age <10 giây, status/progress tăng, queue không tăng dai dẳng,
   `packets_committed` tăng khi máy thực sự phát dữ liệu, 3002 được chọn khi
   có Service packet ổn định đủ ngưỡng; fallback chỉ có lý do rõ ràng.
   Kiểm tra ready outbox và handoff OIE, không suy ra "không mất dữ liệu" từ
   `outbox=0` hoặc TCP `Established`.
5. Nếu `WRITER_STALLED`, STALE, queue đầy, hash/config sai, raw sequence
   lùi, delivery thiếu/trùng, không đủ chỗ đĩa hoặc handoff ngừng, thu bằng
   chứng và rollback theo hướng dẫn. Chỉ một tiến trình được hoạt động.

## 5. Tiêu chí nghiệm thu và phản hồi

Không đánh dấu thành công khi chưa có số liệu theo thời gian. Một canary đạt
điều kiện sơ bộ khi các giá trị ở Bước C ổn định, không có lỗi raw/outbox,
và các thiết bị có Service packet hợp lệ quay về Service sau recovery/hold-down.
Máy không phát Service packet cần báo riêng; không ép chọn Service.

Tạo `collector/reports/2026-10-24_collector-hf-cutover-target.md` với: UTC,
commit/hash EXE, cấu hình ngưỡng (chỉ giá trị không bí mật), PID cũ/mới,
baseline/post deltas từng port, tuổi packet, queue, status/progress, DB/WAL,
outbox, thời gian startup, backup/rollback đã thử, những gate `PASS/FAIL/
NOT_EXECUTED`, sự cố và quyết định tiếp tục/hoãn/rollback. Cập nhật
`collector/STATUS.md` bằng snapshot mới có thời gian rõ ràng; `git push`
phản hồi. Không gửi tên/ID bệnh nhân, license, config materialized, raw packet
hay dump nguyên trạng lên GitHub.

72 giờ soak đóng gói, reboot/logout/forced-kill, preflight tải bệnh viện và
rollback rehearsal là gate **trước** cutover; hiện đều `NOT_EXECUTED`.
Canary 7 ngày là gate **sau** cutover, trước khi đề xuất phát hành rộng.
Chỉ đánh dấu PASS sau khi có báo cáo tương ứng.
