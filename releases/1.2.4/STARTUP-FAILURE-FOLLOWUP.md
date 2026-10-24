# ICU-B: thu bằng chứng sau khi 1.2.4 rollback

## Đã xác nhận và chưa xác nhận

[Báo cáo máy đích](../../reports/2026-10-24_icu-b-update-1.2.4-report.md) ghi nhận candidate 1.2.4 hợp lệ, preflight PASS, nhưng updater 1.2.1 hết hạn chờ readiness 120 giây rồi rollback về 1.2.1, `READY/ROLLED_BACK`, không đổi schema. Vì thế các sửa lỗi của 1.2.4 chưa được áp dụng tại ICU-B.

Mã nguồn `Wait-PFReady` kiểm API, Web rồi Analyzer trong một khối try/catch và chỉ báo lỗi tổng khi hết hạn. Báo cáo chưa kèm log từng service hoặc phép đo thời gian hashing; kết luận cạnh tranh I/O là **giả thuyết**, chưa đủ bằng chứng gọi là nguyên nhân gốc. API và Web mỗi tiến trình thực hiện hai lượt kiểm manifest lúc startup; Analyzer thực hiện một lượt. Đây là công việc lặp có thể góp phần làm khởi động chậm, nhưng chưa xác định endpoint nào làm vòng readiness thất bại ở ICU-B.

Sáu treatment giữ nguyên ID/start time/journal chứng minh dữ liệu trước cập nhật còn nguyên. Các mốc journal được báo đều trước lần rollback; một tổng receipt tích lũy không chứng minh có gói mới sau 03:14:55. PF_009/PF_010 còn `IN_PROGRESS` nhưng mốc cuối từ 22/10; cần phân biệt ca chưa đóng trong DB với thiết bị đang gửi dữ liệu.

Lần nâng cấp kế tiếp vẫn chịu updater của 1.2.1: chỉ tăng timeout trong release mới sẽ không thay ngưỡng 120 giây đang thực thi. Chưa sửa/chèn file vào release đã ký, chưa tạo 1.2.5 dựa riêng vào giả thuyết này.

## Prompt gửi agent ICU-B

Hãy thu bằng chứng **chỉ đọc** cho lần update 1.2.4 bị rollback. Giữ máy ở bản 1.2.1 đang hoạt động; không chạy lại updater, không restart services, không đổi `update.json`, không xóa `releases\1.2.4` hoặc backup. **Bỏ qua hoàn toàn Mirth/OIE**, không mở UI, kiểm queue, sửa channel hay chờ `delivery_id`.

1. Đọc tại máy đích các log `prismaflex-api`, `prismaflex-web`, `prismaflex-analyzer` trong `C:\PrismaFlex\shared\logs` và Windows Service/Application events quanh **24/10/2026 03:10–03:17 +07:00**. Kiểm tra cả log đã rotate. Lập timeline: lệnh start, PID/exit code, lỗi manifest/license/runtime/schema/import, thời điểm API listening, Next ready và Analyzer ready. Trích nguyên lỗi kỹ thuật đã khử định danh; không suy ra hashing chậm chỉ từ lỗi deadline. Nếu log không có mốc bắt đầu/kết thúc kiểm manifest, ghi rõ không đo được.
2. Kiểm tra hiện tại `install-state.json`/`update.json` chỉ các trường version/phase/revision/migration_started/backup_id, ba service và các endpoint 8000 `/internal/ready`, 3000 `/login`, 15555 `/health`. Kiểm cả SCM dependencies và các thẻ `<depend>` trong WinSW XML: updater cũ ghi lại XML nên không mặc định dependency thủ công còn nguyên. Không sửa cấu hình ở bước này.
3. Nếu hệ thống đang ổn định, đo **một lần tuần tự** thời gian và exit code của verifier 1.2.1 với `verify-release --directory C:\PrismaFlex\releases\1.2.4 --deployment`; đây chỉ là đọc/kiểm chữ ký. Không chạy nhiều verifier song song để tạo tải, không chạy `serve`/`serve-web` của candidate cạnh dịch vụ hiện hành. Kết quả khi cache đã ấm không chứng minh thời gian startup lúc sự cố.
4. Dùng truy vấn DB chỉ đọc hoặc API hiện có để báo theo từng thiết bị: timestamp nhận/xử lý gói mới nhất **sau 03:14:55**, số receipt mới trong khoảng sau rollback và journal ghi thêm nếu đã tới lịch snapshot. So ID/start time với snapshot trước update; chỉ gửi số liệu khử định danh. Phân biệt PF_009/PF_010 đã stale từ trước với lỗi do update. Nếu chưa có dữ liệu mới, ghi CHƯA CHỨNG MINH GHI TIẾP; không tự sửa outcome hay tạo journal.
5. Lưu kết quả khử định danh vào `reports/2026-10-24_icu-b-startup-evidence.md`, ghi rõ mục không có bằng chứng. Không gửi raw telemetry, config/mật khẩu/connection string, license, fingerprint hoặc định danh bệnh nhân. Sau đó báo lại để chủ phát hành chốt bản sửa và đường nâng cấp; không thử lại 1.2.4 trong lượt thu bằng chứng này.
