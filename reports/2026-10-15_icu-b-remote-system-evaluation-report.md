# Báo cáo Đánh giá Hệ thống WebApp ICU-B Từ xa (Sau 27+ Ngày Vận hành)

- **Ngày đánh giá**: 2026-10-15
- **Môi trường nguồn**: Máy trạm ICU-B Bệnh viện Chợ Rẫy (IP: `192.168.5.248`)
- **Đối tượng gửi**: Nhóm kỹ sư & Agent tại máy Develop (Remote Analysis & Program Refactoring)
- **Tình trạng uptime**: **27 ngày liên tục** (từ 18/09/2026 đến 15/10/2026, PM2 Uptime: 27D)

---

## 1. Tóm tắt Tình trạng Hệ thống (Executive Summary)

Sau 1 thời gian dài vận hành thực tế tại khoa ICU-B, hệ thống đã duy trì hoạt động ổn định và tích lũy khối lượng dữ liệu lâm sàng rất lớn:

| Thành phần | Công nghệ / Dịch vụ | Trạng thái | Tài nguyên / Uptime | Ghi chú |
|---|---|---|---|---|
| **icub-backend** | Python FastAPI / Uvicorn (PID 9812) | **ONLINE** | 27D uptime, ~75.6 MB RAM | Xử lý telemetry trực tiếp từ Collector và DB |
| **icub-frontend** | Next.js 16.1.6 Cluster (PID 9724) | **ONLINE** | 27D uptime, ~97.7 MB RAM | Phục vụ WebApp trên Port 3000 |
| **PostgreSQL** | PostgreSQL 16 Service (Port 5432) | **ONLINE** | ~140 MB RAM | Chứa DB `prismaflex_app` và `prismaflex` |
| **PrismaFlex Collector** | PrismaFlexDataCollector (Port 3001/3002) | **ONLINE** | Chạy background | Thu thập serial/socket từ các máy lọc máu |
| **DeepSeek Harness** | DSH Web Engine (Port 3080) | **ONLINE** | 27D uptime | Cầu nối điều khiển và Agent tự động |

---

## 2. Thống kê Tăng trưởng Dữ liệu (So sánh 16/09 vs 15/10)

| Chỉ số dữ liệu | Mốc 16/09/2026 | Mốc 15/10/2026 (Hiện tại) | Tăng trưởng |
|---|---|---|---|
| **PostgreSQL Telemetry Receipts** | 14,073 bản ghi | **34,806 bản ghi** | +20,733 bản ghi (+147%) |
| **PostgreSQL Treatments (`prismaflex`)** | 1 ca | **136 ca điều trị** | Ghi nhận 136 phiên lâm sàng |
| **Treatment Status Events** | 16 sự kiện | **5,546 sự kiện** | Phản ánh đầy đủ chu kỳ vận hành máy |
| **Collector Runtime DB** | 459 MB | **3.18 GB** (SQLite) | Thu thập liên tục 24/7 |
| **Trends DB (`backend/trends.db`)** | 495 KB | 4,000 pressure points | Giới hạn sliding window 4000 điểm áp lực |
| **Alarm History** | 20 sự kiện | **109 sự kiện** cảnh báo | Lưu đầy đủ lịch sử chuông báo động |

---

## 3. Hoạt động Lâm sàng & Thiết bị Ghi nhận Hôm nay (15/10/2026)

### 3.1 Ca điều trị đang chạy trên máy PF_010 (Bệnh nhân: `tinh`)
- **Tập tin raw data**: `treatment_a0995921-fc02-4ba1-b88d-4966a26c94ce.raw.jsonl` (79.5 MB)
- **Tốc độ xử lý**: Nhận telemetry liên tục mỗi 1-2 giây, chế độ `QUEUE_MODE`.
- **Nhật ký báo động (`PF_010/alarms_2026-10-15.log`)**:
  - `[10:17:47] [ADVISORY] [314] Battery Exhausted` -> Tự động xóa (Resilient Cleared).
  - `[10:17:49] [WARNING] [262] Set-up error` -> Tự động xóa.
  - `[10:17:57] [WARNING] [335] Syringe Plunger Not Secured` -> Đã xử lý cố định bơm tiêm.
  - `[10:18:06] [MALFUNCTION] [117, 124] Prime Self-Test` -> Hoàn thành test đuổi khí quả lọc.
  - `[10:21:33] [ADVISORY] [315] Main Power Lost` -> Mất nguồn tạm thời và khôi phục.
  - `[10:22:03] [CAUTION] [195, 196, 194] Flow Problem (Replacement, PBP, Effluent)` -> Cảnh báo lưu lượng dịch thay thế/thẩm tách/dịch thải trong quá trình tăng tải rút dịch.

---

## 4. Các Vấn đề Kỹ thuật Cần Nghiên cứu & Tối ưu (Diagnostic Findings)

Dựa trên toàn bộ log vận hành và cơ sở dữ liệu đã trích xuất, nhóm kỹ sư / agent máy Develop cần lưu ý 4 trọng tâm sau để tái cấu trúc / sửa chương trình:

### Vấn đề 1: Độ trễ xử lý gói tin khi dồn tải (Queue Latency)
- **Bằng chứng (`backend.log`)**:
  ```text
  2026-10-15 10:37:29,307 [INFO] PrismaFlexBackend: Processed PF_010: PF_010,1099.69,1.86,0.00,QUEUE_MODE
  ```
- **Phân tích**: Thời gian xử lý có những đợt tăng vọt lên **1,099 ms** (bình thường 110 - 180 ms). Nguyên nhân do backend xử lý tuần tự qua SQLite và PostgreSQL trên cùng luồng ghi, khi gói tin telemetry đến dồn dập sẽ tạo nút cổ chai (bottleneck).
- **Đề xuất fix**: Tách tiến trình nhận telemetry sang worker queue bất đồng bộ (Background Task / Celery / asyncio queue).

### Vấn đề 2: Tốc độ phình to của Collector Runtime DB (`collector_runtime.db`)
- **Bằng chứng**: Dung lượng database đã vượt **3.18 GB** chỉ trong 1 tháng (trung bình ~100 MB/ngày).
- **Phân tích**: Bảng `packets` lưu toàn bộ raw hex payload mà không có cơ chế rolling purge hoặc VACUUM định kỳ. Nếu chạy 6 tháng đến 1 năm, file này có thể vượt 30-50 GB làm tràn ổ C:.
- **Đề xuất fix**: Bổ sung cron job hoặc background maintenance task:
  - Tự động nén/archive các packet cũ hơn 7 ngày.
  - Thực hiện SQLite `PRAGMA incremental_vacuum` định kỳ hàng tuần.

### Vấn đề 3: Gán phiên điều trị (Unassigned vs Assigned Treatments)
- **Bằng chứng**: Hàng trăm MB dữ liệu vẫn gom dưới tên `treatment_unassigned_PF_010.raw.jsonl` (242 MB) và `treatment_unassigned_PF_007.raw.jsonl` (81 MB).
- **Phân tích**: Điều dưỡng hoặc bác sĩ tại buồng bệnh bật máy lọc máu trước khi thao tác tạo phiên trên WebApp, dẫn đến việc dữ liệu thu thập không tìm thấy `treatment_id` hợp lệ và phải lưu vào bucket `unassigned`.
- **Đề xuất fix**: Thiết kế cơ chế "Retroactive Binding" (Gán bù phiên): Cho phép người dùng trên WebApp chọn một khoảng thời gian unassigned đã ghi nhận để gắn vào hồ sơ bệnh án của bệnh nhân sau đó.

### Vấn đề 4: Cảnh báo đa lockfile trong Next.js Frontend
- **Bằng chứng (`icub-frontend-error-1.log`)**:
  ```text
  Warning: Next.js inferred your workspace root, but it may not be correct.
  Detected multiple lockfiles: D:\Block\CentralConnect\package-lock.json and frontend\package-lock.json
  ```
- **Đề xuất fix**: Đồng nhất cấu hình monorepo hoặc thêm `outputFileTracingRoot: path.join(__dirname, '../')` trong `next.config.js`.

---

## 5. Danh mục Tài nguyên Đã Xuất

### A. Đã Đồng bộ lên GitHub (`https://github.com/DinhLucent/PrismaFlex-Agent-Bridge.git` - Nhánh `main`)
*Tổng dung lượng: 90.5 MB (an toàn, đầy đủ mã nguồn & log rút gọn)*

1. **`data/CentralConnect_source_lean.zip`** (26.24 MB):
   - Toàn bộ mã nguồn chương trình WebApp ICU-B (`backend/`, `frontend/`, `prismaflex_lib/`, `scripts/`, `docs/`, `ecosystem.config.js`, batch scripts).
   - Đã loại bỏ các thư mục rác/vendor (`node_modules`, `.next`, `data`, `logs`, `tools/done`).
2. **`data/postgres/`**:
   - `prismaflex_app_full.sql.gz` (2.98 MB): Dump đầy đủ DB `prismaflex_app` (34,806 telemetry receipts).
   - `prismaflex_db_full.sql.gz` (336 KB): Dump đầy đủ DB `prismaflex` (136 treatments, 5,546 status events).
3. **`data/trends/`**:
   - `centralconnect_trends.db` (487 KB): SQLite DB đang active.
   - `trends.db` (524 KB): SQLite DB PrismaFlex.
   - Toàn bộ thư mục `ALARM_LOGS` (tất cả các máy, bao gồm log ngày 15/10).
4. **`data/logs/`**:
   - `centralconnect_backend.log` (3.8 MB), `centralconnect_performance.log` (1.5 MB), `centralconnect_replay_status.log`, `centralconnect_errors.log`.
   - `collector_service.log.gz` (320 KB nén từ 10.5 MB).
5. **`data/config/`**:
   - `pm2_processes.json`: Dump trạng thái runtime của PM2.
   - `collector_service.json`, `collector_status.json`, `runtime.json`, v.v.
6. **`data/raw_samples/`**:
   - Mẫu 200 dòng đầu và cuối của tất cả các phiên điều trị lớn (`treatment_a0995921...`, `treatment_08ca3033...`, `treatment_34cefda0...`, `PF_010`).

### B. Lưu trữ trong Thư mục USB Export (`D:\PrismaFlex-ICU-B-USB-Export\`)
*Dung lượng: ~4.2 GB (Dành cho việc cắm USB copy toàn bộ sang máy Develop)*
- `collector/collector_runtime.db` (3.18 GB)
- `raw_treatments/*.raw.jsonl` (~950 MB gồm toàn bộ các file raw data 100%)
- `database/prismaflex_app_full.sql` & `prismaflex_db_full.sql` (Bản dump chưa nén)
- `README_USB_TRANSFER.txt` (Tài liệu hướng dẫn kỹ sư)

---

## 6. Hướng dẫn Khôi phục & Đánh giá tại Máy Develop

1. **Giải nén mã nguồn chương trình**:
   ```bash
   unzip data/CentralConnect_source_lean.zip -d CentralConnect/
   cd CentralConnect/frontend && npm install
   ```
2. **Khôi phục cơ sở dữ liệu**:
   ```bash
   gzip -d -k data/postgres/prismaflex_app_full.sql.gz
   gzip -d -k data/postgres/prismaflex_db_full.sql.gz
   psql -U postgres -d prismaflex_app -f data/postgres/prismaflex_app_full.sql
   psql -U postgres -d prismaflex -f data/postgres/prismaflex_db_full.sql
   ```
3. **Phân tích mã nguồn và nhật ký**:
   - Tham chiếu file log `data/logs/centralconnect_backend.log` và `data/trends/ALARM_LOGS/PF_010/alarms_2026-10-15.log`.
   - Tiến hành kiểm tra và sửa đổi các bottleneck đã nêu tại Mục 4.
