# Review toàn diện trong phạm vi bàn giao — 23/09/2026

**Chọn 1.2.3 cho máy đích.** 1.2.2 còn hiển thị chart/monitor theo timezone trình duyệt ở một số chỗ. Đã tái hiện bằng browser UTC và Việt Nam: cùng điểm nhưng nhãn 09:43/16:43. 1.2.3 sửa trục chart, tooltip, header, thời gian nhận/sự kiện và Machine Time trên monitor; thời gian máy ưu tiên `meta.timestamp` canonical.

Source chức năng 1.2.3: `029d0eebd6dc51d556585d69b9570cfe8764732a`. API, Analyzer, runtime, migrations và updater giữ nguyên byte từ 1.2.2; chỉ build lại web, đổi metadata version và ký manifest mới. Không thay bản 1.2.2 đã phát hành tại chỗ.

## Bằng chứng kiểm tra

| Nhóm | Kết quả | Phạm vi |
|---|---|---|
| Toàn bộ treatment contracts, strict | **253 PASS** | PostgreSQL disposable thật; session/reconnect/patient switch, duplicate/late/backfill, durable receipt/crash/restart, journal, approval/manual edit/audit, analyzer, concurrency và export. Không xfail che lỗi. Run `09a3f53dc68b`. |
| Dump/restore PostgreSQL thật | **1 PASS** | DB có tên ngẫu nhiên do test tạo, bảo toàn Unicode/schema; từ chối restore đè source hoặc target không rỗng. Đây là test trước đó bị skip, nay đã bật chạy. |
| Browser trên production web build 1.2.3 | **4 PASS** | History/live, reconnect bằng reload, đổi patient không reload, timezone UTC/Vietnam. Test timezone kiểm tra **nhãn trục thực sự hiển thị và Machine Time**, không chỉ tên bệnh nhân. |
| Time/chart helpers | **10 PASS** | Dedup/order/buffer/invalid timestamp và legacy wall-clock ở UTC, Việt Nam, New York. |
| Build frontend | **PASS** | Next.js production và TypeScript. |
| Standalone proxy | **2 PASS** | HTTP/cookie/Unicode/WebSocket trên hai loopback host/cổng, chạy chính thư mục web trong release 1.2.3. |
| Chữ ký và inventory | **PASS** | Audit 1.652 tệp, ký manifest mới; verifier 1.2.1 chấp nhận metadata/signature 1.2.3. Đối chiếu 134 tệp backend/runtime không thay đổi so với 1.2.2. |
| Unit/release trước đó, backend giữ nguyên | **83 PASS / 112 PASS** | Kết quả đợt 1.2.2; không gọi đây là lần chạy mới toàn bộ. Test release còn một skip lúc đó là dump/restore đã chạy bổ sung ở trên. |

Test browser cũ dùng timestamp cố định và chỉ kiểm tra tên ca. Lần chạy lại ban đầu fail vì dữ liệu trở thành stale. Đã sửa fixture dùng event time hiện tại chuẩn +07:00, rồi thêm assert nhãn trục. Test mới fail trên build 1.2.2 và pass trên 1.2.3, chứng minh nguyên nhân và hiệu quả sửa.

## Những gì chưa được chứng minh

- Chưa chạy updater với Windows Service/DB sản xuất tại máy đích. State-machine test có mock services; không thay thế nghiệm thu thực tế.
- Chưa chạy 100.000 gói hoặc soak 60 phút. Burst trước đó vượt SLO delivery latency; không khẳng định chịu tải lớn hoặc không rò bộ nhớ.
- Browser reconnect hiện thử bằng reload; chưa chứng minh mọi trường hợp mất mạng lâu tự nối lại và bù đủ từng điểm.
- Replay sáu file dữ liệu gốc dùng MemoryRecordingDb/mock ACK. Các test PostgreSQL thật bổ sung dùng dữ liệu giả; không được đánh đồng hai loại bằng chứng.
- Giờ nhận, giờ sự kiện thiết bị, và đồng hồ workstation là ba nguồn khác nhau. Fix hiển thị không sửa clock vật lý lệch. Giữ timestamp canonical +07:00 từ decoder và UTC thật ở các trường received_at_utc; không đổi hợp đồng upstream khi update WebPlatform.
- `uf_hourly` giữ nghĩa tốc độ UF mục tiêu theo hợp đồng cũ; không diễn giải là chênh thể tích dịch thực tế giữa hai giờ.
- Một gói patient ID khác và placeholder có hành vi riêng theo FSM/dashboard confirmation. Test pass không có nghĩa mọi thay đổi tên đều phải tách ca ngay theo cùng một ngưỡng; agent nghiệm thu cả treatment và chart.

## Kết luận cho agent nhận

Hướng dẫn đã đủ cho **cập nhật có kiểm tra từ installation protocol 2 tương thích**, bao gồm tải online/offline, preflight/postflight, backup requirements, lỗi/rollback, cài mới và activation khi cần, cùng mẫu báo cáo. Thiếu license hợp lệ/DB credentials/quyền Administrator hoặc hàng đợi OIE chưa rõ thì phải xử lý điều kiện đó; không tự bỏ kiểm tra.

Chỉ xác nhận hoàn tất khi máy đích có services/ready/login/ingest/chart/journal đạt. Giai đoạn đầu chấp nhận gián đoạn treatment qua update, không tự APPROVED/COMPLETED hoặc xóa ca.
