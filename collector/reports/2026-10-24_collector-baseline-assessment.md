# [REP-COL-0001] Đánh giá Hiện trạng Cơ sở Phân hệ Collector (Baseline Assessment)

- **Ngày ghi nhận**: 2026-10-24 01:50:00 (GMT+7)
- **Nguồn dữ liệu**: Tổng hợp từ kiểm tra hiện trường ICU-B và file trạng thái `collector_status.json`
- **Mục đích**: Thiết lập mốc đối chuẩn (baseline benchmark) ban đầu cho không gian làm việc `collector/`

---

## 1. Trạng thái Dịch vụ & Bộ đệm

- **Dịch vụ Windows**: `PrismaFlexCollectorService` (Trạng thái: `RUNNING`)
- **Instance ID**: `dcd785d8cadb40ef98e12d045fac1c60`
- **Uptime**: ~27 ngày hoạt động không gián đoạn
- **Dung lượng Database SQLite**: ~3.18 GB (WAL mode đang hoạt động ổn định)
- **Dung lượng ổ cứng trống**: 383.99 GB (Ổ C:\)
- **Số gói tin đã cam kết**: 3,412,066 gói
- **Tổng dung lượng nhận**: 7,081,929,450 bytes (~7.08 GB)
- **Hàng đợi bộ ghi (Writer Queue)**: 7 / 4096 (Sạch sẽ, không ứ đọng)
- **Mã lỗi nghiêm trọng**: `None`

---

## 2. Kết nối Socket & Thiết bị Hiện trường

| Thiết bị | IP | Port 3001 (User) | Port 3002 (Service) | Đánh giá Kỹ thuật |
|:---:|:---:|:---:|:---:|---|
| **PF_003** | `192.168.5.23` | Active | Active | Dòng dữ liệu liên tục, ổn định |
| **PF_005** | `192.168.5.25` | Active | Active | Dòng dữ liệu liên tục, ổn định |
| **PF_006** | `192.168.5.26` | Active | Active | Dòng dữ liệu liên tục, ổn định |
| **PF_011** | `192.168.5.31` | Active | Active | Dòng dữ liệu liên tục, ổn định |
| **PF_009** | `192.168.5.29` | Reconnect_Wait | Reconnect_Wait | Timeout do ngắt cáp/tắt máy đầu giường |
| **PF_010** | `192.168.5.30` | Reconnect_Wait | Reconnect_Wait | Timeout do ngắt cáp/tắt máy đầu giường |
| **PF_004** | `192.168.5.24` | Offline | Offline | Ca lọc đã đóng |
| **PF_007** | `192.168.5.27` | Offline | Offline | Ca lọc đã đóng |
| **PF_001, 002, 008** | - | Standby | Standby | Máy dự phòng |

---

## 3. Đánh giá Chuỗi Tiếp nhận Hạ nguồn (Downstream Handoff)

- **Outbox Ready Queue**: `0` file tồn đọng tại `C:\ProgramData\PrismaFlex\Collector\outbox\ready`.
- **Kênh OIE Mirth Connect (`PF_01_RAW_DECODE`)**: Đã xử lý 398,375 gói, không có gói nghẽn (`status = 'Q'`: 0).
- **Backend Telemetry Receipts (`prismaflex_app`)**: Tiếp nhận và hoàn tất 392,673 bản ghi, độ trễ tức thời.

---

## 4. Kết luận & Đề xuất

1. Phân hệ Collector hiện tại đang vận hành ở trạng thái kỹ thuật lý tưởng, không có hiện tượng rò rỉ bộ nhớ hay nghẽn hàng đợi ghi đĩa.
2. Cần duy trì kênh giám sát thông qua `collector/` để kịp thời phát hiện bất thường khi các máy lọc online phát sinh cảnh báo kỹ thuật hoặc mất gói.
