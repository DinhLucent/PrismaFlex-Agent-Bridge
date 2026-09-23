# Review 1.2.2 — 23/09/2026

Kết luận: đủ cơ sở bàn giao bản ứng viên để nghiệm thu máy đích; chưa khẳng định mọi kịch bản thực tế hoặc tải lớn đều đạt.

Source DSH: `9fea5065496704f2a63637dd3e816a5f168fce86`.
Source sau review: `886cc46afdfe842acc9ee6abe719179ac8bbc592`, nhánh `deepseek/clock-chart-journal-validation-20260923`.
API/Analyzer không thay đổi giữa hai commit; web được build lại sau hai sửa frontend. Không push source repository trong đợt bàn giao này.

## Đã chạy lại trên máy build

| Nhóm | Kết quả | Phạm vi bằng chứng |
|---|---|---|
| Unit backend | 83 PASS | Bao gồm replay journal; không thay thế replay qua toàn pipeline thật. |
| Release | 112 PASS, 1 SKIP | Có state machine PowerShell update/rollback; verifier/DB/services được mock ở nhóm này. Test dump/restore PostgreSQL opt-in bị skip. |
| Operational + upgrade contracts | 19 PASS | PostgreSQL disposable thật; HTTP test client và recorder. 16 kịch bản vận hành + 3 mô phỏng update. |
| Durable receipt | 1 PASS | HTTP → receipt PostgreSQL → worker → treatment/journal, đối soát trạng thái receipt. |
| Chart/time helpers | 10 PASS | Sắp xếp, dedup, giới hạn buffer, timestamp; có kiểm tra legacy wall-clock ở UTC, Việt Nam và New York. |
| Standalone web proxy | 2 PASS | Cùng bản web build lại, hai loopback host/cổng động; HTTP, cookie, Unicode và WebSocket với API giả lập. |
| Build và chữ ký | PASS | API + Analyzer Nuitka, web Next.js build/TypeScript; audit 1.652 tệp. EXE verifier của cả 1.2.1 và 1.2.2 xác minh chữ ký/deployment metadata 1.2.2 thành công. |

Các lần thử đầu gặp lỗi hạ tầng import/thư mục tạm; kết quả trên là lần chạy lại đã hoàn tất với cấu hình import và thư mục tạm riêng. Không có sửa production để làm test pass.

## Sửa thêm sau review DSH

- Nhánh chart live dùng trực tiếp `mergeSeries`, thay cho nối điểm vào cuối. Hàm đã kiểm thử sắp xếp/dedup nay được dùng ở đường chạy live; bỏ chặn toàn bộ packet chỉ vì timestamp trùng điểm access cuối.
- Chuỗi wall-clock legacy không có offset và hậu tố legacy ` UTC` được hiểu rõ là giờ Việt Nam, không phụ thuộc timezone máy xem. ISO có `Z` hoặc offset giữ đúng instant.
- Media có hướng dẫn 1.2.2; loại bỏ báo cáo smoke 1.1.2 khỏi gói để tránh hiểu nhầm là bằng chứng của bản mới.

## Các giới hạn phải biết

1. Ba test mang tên upgrade không cài/gỡ Windows Service. Test active treatment tự gán COMPLETED và APPROVED rồi restart recorder; đây là setup nhân tạo, không chứng minh updater tách ca đúng. Hướng dẫn không dùng thao tác đó.
2. Replay sáu file của DSH dùng MemoryRecordingDb và mock ACK; không gọi nó là kiểm chứng full ingress/OIE/DB thật. Bài durable receipt dùng dữ liệu giả đã chạy riêng.
3. Browser E2E DSH chủ yếu kiểm tra DOM có đường chart và tên ca; chưa chứng minh đầy đủ giá trị từng điểm hoặc mọi lần reconnect. Chưa chạy lại browser E2E sau hai sửa frontend trong review này; cần nghiệm thu chart tại máy đích.
4. Burst DSH ghi nhận delivery latency vượt SLO. Chưa chạy 100.000 gói hoặc soak 60 phút; không kết luận không rò bộ nhớ.
5. Clock của thiết bị có thể lệch clock Collector. Card giờ nhận và chart giờ sự kiện có thể khác hợp lệ; fix timezone không đồng bộ đồng hồ vật lý.
6. Tên `uf_hourly` vẫn theo hợp đồng hiện có là giá trị tốc độ UF mục tiêu, không phải lượng dịch thực tế lấy chênh giữa hai mốc. Không diễn giải sai ý nghĩa cột.
7. Chưa thực hiện cập nhật Windows Service trên máy đích. Agent nhận phải thực hiện checklist và báo cáo riêng.

Không kèm raw packet, database, mã bệnh nhân hay secrets. ZIP chỉ chứa phần mềm, tài liệu và metadata phát hành; Collector/OIE/PostgreSQL không được đóng gói chung.
