# Báo cáo Điều tra & Trích xuất Dữ liệu Hệ thống WebApp: ICU-B

- **Thời gian trích xuất**: 2026-09-16
- **Môi trường**: Bệnh viện Chợ Rẫy - Đơn vị Hồi sức Tích cực ICU-B
- **Hệ điều hành / Máy chủ**: Windows Server, IP `192.168.5.248`
- **Phiên bản phần mềm**: PrismaFlex Web Platform `1.2.1` (DB Revision: `d4b2a8f91c30`)
- **Mục tiêu**: Thu thập toàn bộ log, cơ sở dữ liệu, thông số điều trị (treatments), dữ liệu thô (rawdata), cấu hình để nghiên cứu và sửa lỗi chương trình WebApp.

---

## 1. Tổng quan Kiến trúc Dữ liệu & Thiết bị tại ICU-B

Hệ thống kết nối và thu thập dữ liệu từ các máy lọc máu liên tục PrismaFlex trong khoa ICU-B thông qua mạng nội bộ:
- **Collector Service**: Lắng nghe và kết nối tới các máy PrismaFlex tại dải IP `192.168.5.23` - `192.168.5.31` qua 2 cổng `3001` (User stream) và `3002` (Service stream).
- **Pipeline OIE (Open Integration Engine)**: Giải mã gói tin RS232/Ethernet, chuẩn hóa thành telemetry format và đẩy vào WebApp.
- **Backend API & WebApp**: PostgreSQL `prismaflex_app` + SQLite `trends.db` lưu trữ phiên điều trị, áp lực, báo động và thông số lâm sàng.

### Danh sách thiết bị ghi nhận:
| Device ID | IP thiết bị | Trạng thái ghi nhận | Ca điều trị gắn liền | Ghi chú |
|---|---|---|---|---|
| **PF_006** | `192.168.5.26` | **LIVE (Đang chạy)** | `d6adb201-4f93-536e-b6ef-e4534aa25770` | Bệnh nhân `g15`, quả lọc `Oxiris`, 15 bản ghi journal |
| **PF_007** | `192.168.5.27` | **LIVE (Đang truyền)** | `unassigned` | 16.7 MB raw data, đang kết nối port 3001 & 3002 |
| **PF_010** | `192.168.5.30` | **Ngắt kết nối gần đây** | `unassigned` | 226.8 MB raw data (93,425 stream packets) |
| **PF_008** | `192.168.5.28` | **IDLE** | `unassigned` | 2.2 MB raw data |
| **PF_011** | `192.168.5.31` | **IDLE (Calibration)** | `unassigned` | 42 KB raw data (trạng thái CALIBRATION) |

---

## 2. Chi tiết Dữ liệu Phiên điều trị (Treatments)

### 2.1 Ca điều trị hoạt động: `d6adb201-4f93-536e-b6ef-e4534aa25770`
- **Thiết bị**: `PF_006`
- **Mã bệnh nhân**: `g15`
- **Quả lọc (Filter)**: `Oxiris` (ID: 8)
- **Thời gian bắt đầu**: `2026-09-16 06:36:56+07`
- **Phiên bản firmware máy**: `SW8.20V04R00`
- **Tổng số gói tin đã nhận**: > 3,688 packets
- **Thời gian chạy**: ~37,037 giây
- **Trạng thái FSM**: `RECORDING` / `IN_PROGRESS`

### 2.2 Dòng nhật ký lâm sàng (`treatment_journal_rows` - 15 dòng):
Bao gồm các mốc giờ (`H00` đến `H05`) và các mốc thay đổi y lệnh (`OC_01` đến `OC_04`):
- **Tốc độ máu (Qb)**: Duy trì 180 mL/phút.
- **Dịch thay thế (Qs)**: 1000 mL/h.
- **Dịch thẩm tách (Qd)**: 1000 mL/h.
- **Qpbp (Pre-blood pump)**: Tăng từ 200 lên 400 mL/h tại `OC_02` (08:24).
- **Mục tiêu rút dịch (UF Target)**: Ban đầu 0 mL/h, tăng lên 100 mL/h tại `OC_03` (08:37), và 150 mL/h tại `OC_04` (12:10).
- **Áp lực**:
  - Áp lực đường vào (Pa): dao động từ -47 mmHg đến -103 mmHg.
  - Áp lực đường về (Pv): dao động từ 55 mmHg đến 73 mmHg.
  - Áp lực màng lọc (Pbe): 86 mmHg đến 110 mmHg.
  - Áp lực xuyên màng (TMP): 44 mmHg đến 61 mmHg.

---

## 3. Các Vấn đề Kỹ thuật Cần Nghiên cứu Fix trên WebApp

1. **Vấn đề phân loại Ca điều trị Unassigned (Điển hình là PF_010 và PF_007)**:
   - Máy `PF_010` gửi tới hơn 226 MB dữ liệu raw (`treatment_unassigned_PF_010.raw.jsonl`) nhưng chưa được gắn `treatment_id` trong cơ sở dữ liệu PostgreSQL.
   - Cần kiểm tra logic phân loại FSM của backend: điều kiện mở ca điều trị tự động khi nhận packet `RECORDING` hoặc khi máy đổi chế độ điều trị từ `CALIBRATION` / `STANDBY` sang `RUN`.
2. **Xử lý lệch thời gian truyền nhận (Network Transmission Latency)**:
   - Bản vá 1.2.1 vừa áp dụng đã bổ sung `meta.collector_received_at_utc`. Tuy nhiên, các bản ghi cũ từ `PF_010` và `PF_007` trong queue mode bị trễ do Collector/OIE đệm gói, cần tối ưu hóa luồng WebSocket push ra WebApp.
3. **Quản lý kích thước file Raw Data & DB SQLite**:
   - `collector_runtime.db` đã đạt 438 MB chỉ sau vài ngày hoạt động do lưu chi tiết từng byte frame. Cần cơ chế dọn dẹp (housekeeping/vacuum) hoặc rotation cho DB này để tránh đầy ổ đĩa server.

---

## 4. Phân loại Thư mục Xuất Dữ liệu

### A. Dữ liệu đẩy lên GitHub (`PrismaFlex-Agent-Bridge/data/`)
- `postgres/`: Toàn bộ bảng PostgreSQL xuất định dạng JSON sạch (`treatments.json`, `treatment_journal_rows.json`, `treatment_status_events.json`, `device_state.json`, `telemetry_receipts_summary.json`...).
- `trends/`: Trích xuất 20 sự kiện báo động (`alarm_history.json`), 56 sự kiện tham số (`parameter_events.json`), mẫu áp lực (`pressure_trends_recent_500.json`) và log báo động thô `alarm_logs/`.
- `raw_samples/`: File mẫu raw packet (`PF_011`, `PF_006.gz`, `PF_008.gz`) và 200 dòng đầu + cuối của ca `Oxiris PF_006` và `PF_010`.
- `config/`: Toàn bộ cấu hình hệ thống (`collector_service.json`, `runtime.json`, `collector_status.json`...).
- `logs/`: Các log chính của Backend API, Performance, và Collector.

### B. Dữ liệu NẶNG xuất riêng để copy qua USB (`D:\PrismaFlex-ICU-B-USB-Export\`)
*Người vận hành dùng USB cắm vào máy chủ để copy toàn bộ thư mục này:*
- `raw_treatments/treatment_unassigned_PF_010.raw.jsonl` (**226.88 MB**)
- `raw_treatments/treatment_d6adb201-4f93-536e-b6ef-e4534aa25770.raw.jsonl` (**62.10 MB**)
- `raw_treatments/treatment_unassigned_PF_007.raw.jsonl` (**16.16 MB**)
- `collector/collector_runtime.db` (**438.14 MB**) + WAL (**3.97 MB**)
- `oie_archive/` (**14,766 file JSON payload, 61.33 MB**)
- `database/prismaflex_app_full.sql` (**2.93 MB**) & `prismaflex_app_full.dump` (**1.21 MB**)
- `database/trends.db` (**0.47 MB**)
