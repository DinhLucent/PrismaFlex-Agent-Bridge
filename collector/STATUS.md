# PrismaFlex Collector — Live Status & Sync Ledger

> **Cập nhật gần nhất**: 2026-10-24 02:07:00 (GMT+7)  
> **Trạm giám sát**: ICU-B Bệnh viện Chợ Rẫy (`192.168.5.1`)  
> **Phân hệ**: PrismaFlex Collector Service v2  

---

## 1. Trạng thái Dịch vụ & Môi trường Runtime

| Thành phần | Giá trị hiện tại | Đánh giá | Ghi chú |
|---|---|---|---|
| **Dịch vụ Windows** | `PrismaFlexCollectorService` | **RUNNING** | Tiến trình gốc quản lý socket & SQLite |
| **Startup Type** | `Automatic` | Chuẩn hóa | Tự động kích hoạt khi Windows khởi động |
| **Uptime dịch vụ** | > 27 ngày liên tục | Ổn định | Không phát sinh crash hay fatal error |
| **Mutex toàn cục** | `Global\PrismaFlexCollectorService` | Locked (Owned) | Ngăn chặn tiến trình thứ 2 mở socket |
| **Thư mục Runtime** | `C:\ProgramData\PrismaFlex\Collector` | Sẵn sàng | Chứa DB, logs, status, outbox |
| **Cơ sở dữ liệu SQLite** | ~3.18 GB | Bền vững | Cơ chế ghi WAL (Write-Ahead Logging) |
| **Hàng đợi Outbox** | `<outbound root>\ready` | 0 backlog | Đã chuyển tiếp 100% sang OIE Mirth |
| **Tài nguyên ổ đĩa** | Trống > 380 GB trên ổ `C:\` | An toàn | Ngưỡng cảnh báo tối thiểu: 2 GB |

---

## 2. Ma trận Kết nối 11 Thiết bị Máy lọc PrismaFlex (Device Matrix)

Dải IP mạng LAN nội bộ: `192.168.5.0/24` (Card Realtek 2.5GbE `192.168.5.1` - Cô lập không Gateway).

| Thiết bị | Device ID | Địa chỉ IP | Cổng User (3001) | Cổng Service (3002) | Trạng thái FSM | Bệnh nhân | Ghi chú vận hành |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **PF_001** | `1` | `192.168.5.21` | Disconnected | Disconnected | `IDLE` | - | Dự phòng khoa / Chưa kết nối |
| **PF_002** | `2` | `192.168.5.22` | Disconnected | Disconnected | `IDLE` | - | Dự phòng khoa / Chưa kết nối |
| **PF_003** | `3` | `192.168.5.23` | **Connected** | **Connected** | `RECORDING` | `g6` | **Đang lọc thực tế**, luồng ổn định |
| **PF_004** | `4` | `192.168.5.24` | Offline | Offline | `CLOSED` | `g` | Ca lọc đã đóng thành công |
| **PF_005** | `5` | `192.168.5.25` | **Connected** | **Connected** | `RECORDING` | `g` | **Đang lọc thực tế**, luồng ổn định |
| **PF_006** | `6` | `192.168.5.26` | **Connected** | **Connected** | `RECORDING` | `g` | **Đang lọc thực tế**, luồng ổn định |
| **PF_007** | `7` | `192.168.5.27` | Offline | Offline | `CLOSED` | `truong g24` | Ca lọc đã đóng thành công |
| **PF_008** | `8` | `192.168.5.28` | Disconnected | Disconnected | `IDLE` | - | Không có ca bệnh nhân |
| **PF_009** | `9` | `192.168.5.29` | Reconnect_Wait | Reconnect_Wait | `LIVE` (Treo) | `g14` | Thiết bị offline nhưng ca chưa đóng |
| **PF_010** | `10` | `192.168.5.30` | Reconnect_Wait | Reconnect_Wait | `LIVE` (Treo) | `truong g8` | Thiết bị offline nhưng ca chưa đóng |
| **PF_011** | `11` | `192.168.5.31` | **Connected** | **Connected** | `RECORDING` | `G3` | **Đang lọc thực tế**, luồng ổn định |

---

## 3. Sức khỏe Hàng đợi & Lưu lượng Truyền dẫn

- **Tổng số gói tin đã cam kết (Committed Packets)**: > 3,412,000 gói.
- **Tổng dung lượng đã nạp qua TCP**: > 7.08 GB dữ liệu thô.
- **Độ sâu hàng đợi bộ ghi (Writer Queue Depth)**: Thường trực ở mức `0 - 7` / Capacity `4096` (Hệ thống ghi đĩa đáp ứng tức thời).
- **Hàng đợi chuyển tiếp OIE Mirth**: `d_mm11` và `d_mm9` đạt **0 gói tồn đọng**.

---

## 4. Nhật ký Hoạt động & Đồng bộ Chỉ thị (Sync Ledger)

| Ngày / Giờ | Bên khởi tạo | Mã tham chiếu | Hành động chính | Kết quả |
|---|---|---|---|---|
| **2026-10-24 02:07** | **Target Agent** | `REQ-COL-0002` | Trích xuất đo xa, trạng thái socket và active config của Collector | Hoàn tất thu thập, 4 máy Online (PF_003, 005, 006, 011), 0 tồn đọng OIE |
| **2026-10-24 01:50** | **Dev Agent** | `REQ-COL-0001` | Khởi tạo Dedicated Collector Workspace trên Bridge | Thiết lập xong workspace & chỉ thị ban đầu |
| **2026-10-23 10:45** | **Target Agent** | `REP-SYS-1023` | Rà soát toàn thể hệ thống, socket 3001/3002 và các ca lọc | 4 máy lọc online, 2 máy treo state cần hướng dẫn |
| **2026-10-15 13:45** | **Target Agent** | `REP-COL-1015` | Trích xuất metrics Collector status & DB WAL | Ghi nhận > 3.4 triệu gói tin, Uptime 27 ngày |
