# Hướng dẫn Tinh chỉnh Tham số Vận hành (Collector Tuning Parameters)

Tài liệu này giải thích các tham số trong `collector_service.json` để Dev Agent và Target Agent phối hợp tinh chỉnh khi môi trường mạng hoặc tải lâm sàng có biến động.

---

## 1. Khối Mạng (`network`)

| Tham số | Giá trị mặc định | Giá trị ICU-B đề xuất | Ý nghĩa & Tác động |
|---|---|---|---|
| `connect_timeout_seconds` | `5` | `5` | Thời gian chờ tối đa khi thiết lập TCP handshake với Moxa NPort / máy lọc. |
| `read_timeout_seconds` | `2` | `2` | Thời gian chờ tối đa trên socket khi đọc dữ liệu framed packet. |
| `reconnect_initial_seconds` | `2` | `2` | Thời gian chờ thử lại kết nối lần đầu sau khi đứt liên lạc (Exponential backoff). |
| `reconnect_max_seconds` | `60` | `60` | Giới hạn trần thời gian backoff giữa các lần thử lại kết nối. |
| `silent_connection_timeout_seconds` | `120` | `120` | Ngưỡng ngắt kết nối half-open nếu socket mở nhưng không nhận được bất kỳ byte dữ liệu nào trong 120s. Tránh tình trạng treo socket sau khi máy lọc khởi động lại nguồn. |

---

## 2. Khối Thời gian thực & Lưu trữ (`runtime`)

| Tham số | Mặc định | ICU-B đề xuất | Ý nghĩa & Hướng dẫn Tinh chỉnh |
|---|---|---|---|
| `service_failover_seconds` | `60` | `60` | Nếu luồng Service port 3002 im lặng quá số giây này, bộ chọn luồng tự động chuyển quyền sang User port 3001. |
| `service_recovery_packets` | `5` | `5` | Số gói tin Service port 3002 liên tiếp cần nhận được để xác nhận luồng kỹ thuật đã ổn định trở lại trước khi switch về Service port. |
| `service_recovery_seconds` | `60` | `60` | Khoảng thời gian hold-down bắt buộc trước khi chuyển ngược từ User về Service stream. |
| `service_suspect_seconds` | `30` | `30` | Thời gian luồng Service bị gián đoạn trước khi bị đánh dấu là "suspect" (nghi ngờ). |
| `canonical_retention_days` | `30` | `30` | Số ngày lưu trữ dữ liệu gói tin chuẩn hóa trong SQLite WAL. |
| `candidate_retention_days` | `7` | `14` | Số ngày lưu trữ các gói tin ứng viên (candidate/rejected). Khi ổ đĩa > 300 GB trống, có thể nâng lên 14-30 ngày phục vụ đối soát y khoa. |
| `full_raw_retention_hours` | `48` | `48` | Thời gian lưu trữ toàn bộ dữ liệu thô chi tiết trước khi nén/xoay vòng. |
| `snapshot_interval_seconds` | `10` | `10` | Chu kỳ sinh tệp JSON outbox gửi sang kênh OIE (`PF_01_RAW_DECODE`). |
| `writer_queue_capacity` | `4096` | `4096` | Dung lượng hàng đợi bộ đệm ghi đĩa trước khi ghi vào SQLite. Thường trực < 10. |
| `minimum_free_disk_bytes` | `2147483648` (2 GB) | `5368709120` (5 GB) | Ngưỡng dung lượng trống tối thiểu trên ổ đĩa. Dưới ngưỡng này, dịch vụ sẽ kích hoạt chế độ an toàn bảo vệ đĩa. |

---

## 3. Quy trình Áp dụng Cấu hình An toàn

Mọi thay đổi cấu hình trên máy đích cần tuân thủ một trong hai phương thức:
1. **Qua GUI & UAC Helper**:
   - Mở `PrismaFlexDataCollector.exe` -> Nhấn `Ctrl+S` nhập mã ngày.
   - Sửa tham số -> Bấm **Apply** để helper tự động xác thực, tạo bản sao lưu, và nạp cấu hình mới.
2. **Qua Script Tự động hóa**:
   - Sử dụng script `collector/scripts/Restart-CollectorSafely.ps1` kết hợp kiểm tra tính toàn vẹn cú pháp JSON trước khi thay thế tệp `C:\ProgramData\PrismaFlex\Collector\config\collector_service.json`.
