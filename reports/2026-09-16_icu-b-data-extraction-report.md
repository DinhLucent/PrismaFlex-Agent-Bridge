# Báo cáo Trích xuất Dữ liệu & Log Hệ thống WebApp ICU-B

- **Ngày thực hiện**: 2026-09-16
- **Thiết bị nguồn**: Trạm điều khiển máy Custom (ICU-B) - Chợ Rẫy
- **Phiên bản hệ thống**: PrismaFlex Web Platform `v1.2.1`
- **Mục đích**: Thu thập toàn bộ log vận hành, treatments, raw data, telemetry receipts và database dump nhằm phục vụ nghiên cứu, phân tích và sửa lỗi chương trình tại máy Develop.

---

## 1. Tổng quan Trạng thái Hệ thống ICU-B

Hệ thống ICU-B đã hoạt động liên tục sau đợt cập nhật lên `1.2.1` vào ngày 15/09/2026.
- **Dịch vụ đang chạy**:
  - `prismaflex-api` (Port 8000)
  - `prismaflex-web` (Port 3000)
  - `prismaflex-analyzer` (Port 15555)
  - `PrismaFlexCollectorService` / `PrismaFlexDataCollector` (Thu thập dữ liệu thiết bị)
  - `postgresql-x64-16` (PostgreSQL Database `prismaflex_app` trên Port 5432)
- **Thiết bị kết nối**:
  - Các máy lọc máu cấu hình: PF_003, PF_004, PF_005, PF_006, PF_007, PF_008, PF_009, PF_010, PF_011.
  - Các máy ghi nhận dữ liệu thực tế và sinh log:
    - **PF_006**: Hoạt động tích cực, ghi nhận alarm log ngày 16/09.
    - **PF_007**: Hoạt động tích cực, gửi telemetry liên tục theo chu kỳ queue.
    - **PF_010**: Thu thập khối lượng dữ liệu lớn nhất (~238MB raw jsonl, alarm log ngày 15/09 & 16/09).
    - **PF_008**, **PF_011**: Có phát sinh dữ liệu phiên điều trị ngắn / unassigned.
    - Ca điều trị chính thức: `treatment_d6adb201-4f93-536e-b6ef-e4534aa25770` (65.1MB raw).

---

## 2. Phân loại Dữ liệu & Quy cách Lưu trữ

Theo yêu cầu trích xuất dữ liệu và tuân thủ giới hạn tải lên GitHub (tối đa 100MB/file, khuyến nghị < 50MB/file), dữ liệu được chia làm 2 phần:

### A. Dữ liệu Đồng bộ lên GitHub (`PrismaFlex-Agent-Bridge/data/`)
*Tổng dung lượng: ~26.7 MB (An toàn, đẩy trực tiếp lên Git)*

1. **`data/config/`**: Toàn bộ cấu hình hệ sinh thái:
   - `runtime.json`: Cấu hình API, Analyzer, Database URL, Ports.
   - `collector_service.json`: Danh sách IP/Host các máy lọc máu, tham số kết nối, retention.
   - `collector_status.json`: Trạng thái live của các cổng và thiết bị.
   - `install-state.json`, `update.json`, `site.json`: Trạng thái phiên bản và deployment.
2. **`data/postgres/`**:
   - `prismaflex_app_full.sql.gz` (1.2 MB nén / 3.1 MB gốc): Dump toàn bộ 17 bảng PostgreSQL `prismaflex_app` (chứa 14,073 telemetry receipts, treatments, journals, users,...).
   - Các file JSON trích xuất độc lập cho từng bảng: `treatments.json`, `treatment_journal_rows.json`, `treatment_status_events.json`, `device_state.json`, `telemetry_receipts_recent_500.json`, v.v.
3. **`data/trends/`**:
   - `trends.db` (495 KB SQLite): Lưu trữ đầy đủ bảng xu hướng áp lực (`pressure_trends`), alarms (`alarm_history`), events (`parameter_events`), sessions.
   - Các file JSON export tương ứng (`pressure_trends_recent_500.json`,...).
   - `alarm_logs/`: Log chi tiết cảnh báo của `PF_006` và `PF_010`.
4. **`data/logs/`**:
   - `backend.log` (2.7 MB): Log xử lý dữ liệu backend và chu kỳ queue của thiết bị.
   - `collector_service.log` (294 KB): Log kết nối socket, bắt gói tin từ các IP máy lọc máu.
   - `performance.log` (832 KB): Đo đạc độ trễ và hiệu năng xử lý từng thiết bị.
   - `replay_status.log` (628 KB): Tiến trình replay dữ liệu.
   - Các file `prismaflex-*.wrapper.log`, `*.err.log.old`, `*.out.log.old`.
5. **`data/raw_samples/`**:
   - Mẫu đầu (Head 200 dòng) và mẫu đuôi (Tail 200 dòng) của các file lớn: `PF_010`, `treatment_d6adb...`.
   - File nén gzip đầy đủ của các máy vừa và nhỏ: `PF_006.raw.jsonl.gz`, `PF_007.raw.jsonl.gz`, `PF_008.raw.jsonl.gz`, `PF_011.raw.jsonl`.
6. **`data/oie_archive_full.zip`** (10.5 MB):
   - Nén toàn bộ 14,668 gói tin raw packet JSON được lưu trong OIE archive.

---

### B. Dữ liệu Nặng lưu trữ riêng để Copy qua USB (`D:\PrismaFlex-ICU-B-USB-Export\`)
*Tổng dung lượng: ~796 MB (Dành riêng cho kỹ sư cắm USB copy sang máy Develop)*

| Đường dẫn tệp | Dung lượng | Mô tả nội dung |
|---|---|---|
| `collector/collector_runtime.db` | **459.4 MB** | SQLite database chứa 132,042 raw packets, 14,724 deliveries từ Collector |
| `collector/collector_runtime.db-wal` | **4.16 MB** | WAL file tương ứng của collector runtime |
| `raw_treatments/treatment_unassigned_PF_010.raw.jsonl` | **237.9 MB** | Toàn bộ log raw jsonl liên tục từ máy lọc máu PF_010 |
| `raw_treatments/treatment_d6adb201-4f93-536e-b6ef-e4534aa25770.raw.jsonl` | **65.1 MB** | Toàn bộ log raw jsonl của ca điều trị chính thức |
| `raw_treatments/treatment_unassigned_PF_007.raw.jsonl` | **16.9 MB** | Raw data gốc của máy PF_007 |
| `raw_treatments/treatment_unassigned_PF_006.raw.jsonl` | **3.98 MB** | Raw data gốc của máy PF_006 |
| `raw_treatments/treatment_unassigned_PF_008.raw.jsonl` | **2.30 MB** | Raw data gốc của máy PF_008 |
| `raw_treatments/treatment_unassigned_PF_011.raw.jsonl` | **42 KB** | Raw data gốc của máy PF_011 |
| `database/prismaflex_app_full.sql` | **3.06 MB** | Script SQL phục hồi PostgreSQL hoàn chỉnh |
| `database/prismaflex_app_full.dump` | **1.26 MB** | Bản binary dump chuẩn pg_dump |
| `database/trends.db` | **495 KB** | Cơ sở dữ liệu SQLite xu hướng áp lực |
| `collector/oie_archive_full.zip` | **7.84 MB** | Toàn bộ 14,668 gói tin OIE archive |
| `README_USB_TRANSFER.txt` | **2.5 KB** | Hướng dẫn chi tiết cho kỹ sư copy USB |

---

## 3. Ghi chú Phân tích sơ bộ cho Kỹ sư / Agent máy Develop

1. **Vấn đề kết nối Timeout tại Collector (`collector_service.log`)**:
   - Collector liên tục báo `SILENT_CONNECTION_TIMEOUT` và `TIMEOUTERROR` trên các máy ID: 3, 4, 5, 8, 9, 10, 11 (cổng 3001 và 3002).
   - Hiện tại chỉ có máy **PF_006** và **PF_007** đang gửi dữ liệu đều đặn (ở chế độ `QUEUE_MODE`).
   - Cần kiểm tra lại cấu hình mạng bệnh viện hoặc timeout policy nếu các máy khác đang thực sự bật nhưng không truyền được.

2. **Dữ liệu Unassigned Treatment**:
   - Đa số dữ liệu raw gom về dưới dạng `treatment_unassigned_PF_xxx.raw.jsonl`.
   - Cần kiểm tra logic gán ca điều trị (`treatments` table hiện mới chỉ có 1 ca được tạo chính thức trong DB).

3. **Hướng dẫn khôi phục môi trường test tại máy Develop**:
   - Dùng `data/postgres/prismaflex_app_full.sql.gz` giải nén và nạp vào PostgreSQL local:
     ```bash
     gzip -d -k data/postgres/prismaflex_app_full.sql.gz
     psql -U prismaflex -d prismaflex_app -f data/postgres/prismaflex_app_full.sql
     ```
   - Copy `data/trends/trends.db` vào thư mục `shared/var/` tương ứng.
