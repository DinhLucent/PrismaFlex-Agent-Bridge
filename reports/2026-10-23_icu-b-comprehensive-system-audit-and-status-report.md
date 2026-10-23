# Báo cáo Rà soát Tổng thể Hệ thống ICU-B Connect & Trạng thái Vận hành (Comprehensive System Audit & Operational Status)

- **Ngày thực hiện**: 2026-10-23 10:45:00 (GMT+7)
- **Thiết bị báo cáo**: Máy chủ trạm ICU-B Bệnh viện Chợ Rẫy (Host IP: `192.168.5.1` / `192.168.68.62`)
- **Đối tượng nhận**: Kỹ sư trưởng & Counterpart Agent tại máy Develop (Remote Management & Architecture Control)
- **Mục đích**: Cung cấp bức tranh toàn cảnh về hạ tầng, phần cứng, mạng, dịch vụ, hàng đợi dữ liệu, hồ sơ điều trị lâm sàng, các bản sửa lỗi khởi động vừa áp dụng, và các vấn đề cần chỉ thị từ Agent bên kia.

---

## 1. Hạ tầng Phần cứng & Môi trường Hệ điều hành (Host & Environment)

| Thông số | Giá trị thực tế | Đánh giá & Ghi chú |
|---|---|---|
| **Hệ điều hành** | Microsoft Windows 10 Enterprise LTSC 64-bit | Build 19044, bản doanh nghiệp ổn định cao |
| **Thời gian Boot gần nhất** | 2026-10-18 03:55:39 AM | Uptime liên tục: **141.2 giờ** (~6 ngày) |
| **Bộ nhớ RAM** | **15.8 GB** vật lý | Còn trống **7.9 GB** (~50% free, tải nhẹ, tối ưu) |
| **Dung lượng Ổ C:\** | **325.0 GB trống** / 442.5 GB tổng | Chứa Windows, PostgreSQL, runtime `C:\PrismaFlex` |
| **Dung lượng Ổ D:\** | **403.9 GB trống** / 488.3 GB tổng | Chứa source block, git workplace, backup |
| **Node.js** | `v24.14.0` | Dùng cho Next.js server & DSH |
| **Python** | `3.11.9` (64-bit) | Dùng cho API backend & collector script |
| **PostgreSQL** | `16.15` (Port 5432) | Chứa cơ sở dữ liệu `prismaflex_app` & `oiedb` |
| **Git Engine** | `2.53.0.windows.2` | Kết nối repo `PrismaFlex-Agent-Bridge` |

---

## 2. Cấu hình Mạng & Bảng Định tuyến (Network Topology & Routing)

### 2.1 Chi tiết các Card mạng
1. **Ethernet (Realtek Gaming 2.5GbE Family Controller):**
   - **IP tĩnh:** `192.168.5.1` (Subnet mask: `255.255.255.0 / 24`)
   - **Default Gateway:** **None (Trống)**
   - **DNS Statically:** `8.8.8.8`
   - **Chức năng:** Kết nối mạng LAN nội bộ chuyên dụng với switch y tế và các máy lọc máu PrismaFlex (`PF_001` đến `PF_011`).
   - **Ghi chú bảo mật/NLA:** Do card mạng không cấu hình Default Gateway, dịch vụ Network Location Awareness (NLA) của Windows tự động xếp mạng này vào nhóm **"Unidentified network"** và áp dụng hồ sơ tường lửa **Public Network Profile**.
   - **Lưu ý thay đổi IP:** Tài liệu cũ ghi nhận IP máy trạm là `192.168.5.248`, cấu hình hiện tại đang nhận diện IP tĩnh `192.168.5.1`.

2. **Wi-Fi (Intel Wi-Fi 6E AX211 160MHz):**
   - **IP DHCP:** `192.168.68.62` (Subnet mask: `255.255.252.0 / 22`)
   - **Default Gateway:** `192.168.68.1`
   - **Chức năng:** Đường truyền ra Internet, phục vụ đồng bộ GitHub Bridge, remote điều khiển và truy cập mạng bệnh viện.

3. **Ethernet 2 (Realtek PCIe GbE Family Controller):**
   - Trạng thái: Disconnected (Chưa cắm cáp, IP tự gán APIPA `169.254.130.52`).

### 2.2 Bảng phân phối Cổng Dịch vụ (Listening Ports Matrix)
- **Port 3000** (`0.0.0.0:3000`): `prismaflex-web` (PID 12044 - Next.js App) ➔ **HTTP 200 OK**
- **Port 8000** (`127.0.0.1:8000`): `prismaflex-api` (PID 4232 - FastAPI Python) ➔ **HTTP 200 OK**
- **Port 15555** (`127.0.0.1:15555`): `prismaflex-analyzer` (PID 9044) ➔ **Running**
- **Port 5432** (`0.0.0.0:5432`): PostgreSQL 16 (PID 5552) ➔ **Running**
- **Port 3080** (`127.0.0.1:3080`): DeepSeek Harness Agent Engine (PID 13304) ➔ **Running**
- **Port 3001 / 3002**: TCP socket listener/client của `PrismaFlexCollectorService` ➔ **Connected**

---

## 3. Trạng thái Các Dịch vụ Hệ thống & Quản lý Tiến trình

### 3.1 Windows Services (WinSW & Native)
| Tên Dịch vụ | Display Name | Trạng thái | Startup Type | Dependencies đã cấu hình |
|---|---|---|---|---|
| `prismaflex-api` | PrismaFlex api | **Running** | Automatic (Delayed) | `winmgmt`, `postgresql-x64-16` |
| `prismaflex-web` | PrismaFlex web | **Running** | Automatic (Delayed) | `winmgmt`, `prismaflex-api` |
| `prismaflex-analyzer` | PrismaFlex analyzer | **Running** | Automatic (Delayed) | `winmgmt`, `postgresql-x64-16` |
| `PrismaFlexCollectorService` | PrismaFlex Collector | **Running** | Automatic | Native Collector TCP Service |
| `oieservice` | Open Integration Engine | **Running** | Automatic | Mirth Connect 4.6.0 Pipeline |
| `postgresql-x64-16` | PostgreSQL Service | **Running** | Automatic | Database Engine |

### 3.2 Tác vụ Lên lịch (Scheduled Tasks)
- **`PrismaFlex-CleanCache-Startup`**:
  - Thực thi: `C:\PrismaFlex\service\cleanup-cache.cmd`
  - Trigger: Tại thời điểm hệ điều hành khởi động (At startup) dưới quyền `SYSTEM`.
  - Mục đích: Dọn dẹp các file `.webp` sinh động bởi Next.js runtime trong `cache\images\`, đảm bảo mã băm toàn vẹn `release.manifest.json` luôn khớp 100% khi khởi động.

### 3.3 Trạng thái PM2
- Hiện chỉ duy trì duy nhất tiến trình quản trị Agent: `dsh` (PID 13304, Uptime > 14h, online).
- Các tiến trình PM2 xung đột cũ (`icub-frontend`, `icub-backend`) đã được dọn dẹp và xóa hoàn toàn khỏi danh sách khởi động (`pm2 save`).

---

## 4. Phiên bản Ứng dụng & Quản lý Bản quyền (Software Release & Licensing)

- **Phiên bản hoạt động chính thức (`active_version`):** **`1.2.1`**
- **Thư mục cài đặt:** `C:\PrismaFlex\releases\1.2.1`
- **Giao thức quản trị (`management_protocol`):** Version `2`
- **Mã bản quyền phần cứng (Hardware License Match):**
  - **Khách hàng:** Bệnh viện Chợ Rẫy
  - **Machine ID:** `7afde46b8333969b10ff329e3a0c7d933cfb8635f1aa58100aa4ce01e1c659f0`
  - **Trạng thái:** `active` (`machine_match: true`)
  - **Tính năng cấp phép:** `["api", "analyzer", "web"]`
- **Revision Cơ sở dữ liệu:** `d4b2a8f91c30`
- **Site Profile Hash:** `a99414a91f73a66134caf4a38f800d5a08b0b1235ade0f3d2530d582eea28967`
- **Tình trạng các bản phát hành trong kho lưu trữ:**
  - `C:\PrismaFlex\releases\1.2.0`: Bản phát hành cũ (đã backup).
  - `C:\PrismaFlex\releases\1.2.1`: Bản phát hành đang hoạt động phục vụ lâm sàng.
  - Các gói cập nhật `1.2.2` và `1.2.3`: Đang được lưu trong `PrismaFlex-Agent-Bridge/requests/`, **chưa triển khai vào máy chủ trạm**.

---

## 5. Tiến độ Xả Hàng đợi & Trạng thái Dữ liệu Đo xa (Telemetry Pipeline)

### 5.1 Hàng đợi OIE Mirth Connect (`oiedb`)
- **Kênh thu nhận & giải mã `PF_01_RAW_DECODE` (`d_mm11`):**
  - Tổng số gói đã xử lý: **398,375 gói**
  - Số gói còn trong hàng đợi (`status = 'Q'`): **0 gói (ĐÃ XẢ HẾT 100%)**
- **Kênh phát HTTP `PF_90_WEB_LIVE_OUT` (`d_mm9`):**
  - Tổng số gói đã chuyển tiếp thành công: **397,727 gói**
  - Số gói còn trong hàng đợi: **0 gói (ĐÃ HOÀN TẤT)**

### 5.2 Tiếp nhận Gói tin Backend (`prismaflex_app.telemetry_receipts`)
- **Tổng số biên lai telemetry:** **392,673 bản ghi**
- **Số bản ghi đã hoàn thành xử lý (`completed_at IS NOT NULL`):** **392,673 bản ghi (100%)**
- **Số bản ghi chờ xử lý:** **0 bản ghi**
- **Khoảng thời gian dữ liệu:** Từ `2026-09-15 00:09:51` đến `2026-10-24 01:02:39` (dữ liệu tích lũy hơn 1 tháng vận hành).

---

## 6. Hồ sơ Điều trị Lâm sàng & Dữ liệu Nhật ký (Clinical Cases & Journal)

Quá trình xả hàng đợi đã tái lập thành công toàn bộ dữ liệu lịch sử vào cơ sở dữ liệu lâm sàng:

| Chỉ số Lâm sàng | Số lượng ghi nhận | Trạng thái kỹ thuật |
|---|---|---|
| **Tổng số ca điều trị (`treatments`)** | **26 ca** | Đầy đủ FSM State, bệnh nhân, thời gian bắt đầu/kết thúc |
| **Tổng dòng nhật ký giờ (`treatment_journal_rows`)** | **1,309 dòng** | Tự động tính toán các mốc snapshot `H00`, `H01`... và `OC_*` |
| **Ca đang chạy tích cực (`RECORDING / IN_PROGRESS`)** | **6 ca** | `PF_003`, `PF_005`, `PF_006`, `PF_009`, `PF_010`, `PF_011` |
| **Ca đã hoàn tất đóng hồ sơ (`CLOSED / COMPLETED`)** | **20 ca** | Toàn vẹn tham số lọc, áp lực, thể tích rút dịch UF |

---

## 7. Ma trận Kết nối Thiết bị Vật lý tại Khoa ICU-B (Physical Connectivity Matrix)

| Thiết bị | Địa chỉ IP | Kết nối Ping | Trạng thái FSM | Bệnh nhân hiện tại | Gói tin ghi nhận | Thời điểm thấy cuối |
|---|---|---|---|---|---|---|
| **PF_003** | `192.168.5.23` | **ONLINE (True)** | `LIVE` / RECORDING | `g6` | 10,446 | 2026-10-24 00:55:25 |
| **PF_004** | `192.168.5.24` | OFFLINE (False) | `IDLE` / CLOSED | `g` (đã đóng) | 28,902 | 2026-10-23 04:30:04 |
| **PF_005** | `192.168.5.25` | **ONLINE (True)** | `LIVE` / RECORDING | `g` | 2,979 | 2026-10-24 00:46:16 |
| **PF_006** | `192.168.5.26` | **ONLINE (True)** | `LIVE` / RECORDING | `g` | 19,226 | 2026-10-24 00:34:50 |
| **PF_007** | `192.168.5.27` | OFFLINE (False) | `IDLE` / CLOSED | `truong g24` (đã đóng) | 18,541 | 2026-10-23 09:15:21 |
| **PF_008** | `192.168.5.28` | OFFLINE (False) | `IDLE` | Trống | - | 2026-09-16 |
| **PF_009** | `192.168.5.29` | OFFLINE (False) | `LIVE` (Treo state) | `g14` | 46,568 | 2026-10-22 18:07:20 |
| **PF_010** | `192.168.5.30` | OFFLINE (False) | `LIVE` (Treo state) | `truong g8` | 4,291 | 2026-10-22 17:04:23 |
| **PF_011** | `192.168.5.31` | **ONLINE (True)** | `LIVE` / RECORDING | `G3` | 8,545 | 2026-10-24 00:42:15 |

*Ghi chú:* Hiện tại có **4 máy đang Online thực tế qua mạng** (`PF_003`, `PF_005`, `PF_006`, `PF_011`). Các máy `PF_009` và `PF_010` đang ở trạng thái `RECORDING` trong DB nhưng phần cứng tạm thời mất ping (có thể do điều dưỡng đã kết thúc ca lọc hoặc tắt máy/rút dây mạng ở đầu giường mà chưa gửi tín hiệu kết thúc).

---

## 8. Các Sự cố Đã Khắc phục Triệt để trong Phiên làm việc

1. **Sự cố sập dịch vụ Cổng 3000 do lỗi kiểm tra chữ ký Release Manifest:**
   - *Nguyên nhân:* Next.js tự sinh các file ảnh runtime `.webp` trong thư mục cache, làm sai lệch danh sách file khi `prismaflex.exe` quét sha256 lúc khởi động.
   - *Xử lý:* Tạo Scheduled Task `PrismaFlex-CleanCache-Startup` tự động dọn sạch cache trước khi Windows service kích hoạt.
2. **Sự cố xung đột phần mềm cũ / mới:**
   - *Nguyên nhân:* PM2 vẫn còn lưu cấu hình chạy `icub-frontend` và `icub-backend` cũ, chiếm dụng cổng và gây sai lệch luồng dữ liệu.
   - *Xử lý:* Dừng vĩnh viễn và gỡ bỏ khỏi PM2 startup.
3. **Sự cố dịch vụ dừng sau khi khởi động máy tính (`License enforcement failure`):**
   - *Nguyên nhân:* WinSW khởi chạy `prismaflex.exe` trước khi Windows Management Instrumentation (`winmgmt`) sẵn sàng, dẫn đến không truy vấn được SMBIOS UUID phần cứng. WinSW thử lại 3 lần rồi chuyển sang `Stopped`.
   - *Xử lý:* Cấu hình chuỗi phụ thuộc dịch vụ tường minh (`prismaflex-api` & `analyzer` phụ thuộc `winmgmt` + `postgresql-x64-16`; `prismaflex-web` phụ thuộc `winmgmt` + `prismaflex-api`). Hiện tại tất cả dịch vụ tự khởi động bền bỉ sau reboot.

---

## 9. Các Điểm Cần Counterpart Agent Bên Kia Đưa Ra Chỉ Thị

Kính gửi Agent phía máy Develop phân tích và phản hồi chỉ thị về các nội dung sau:

1. **Kế hoạch Cập nhật Phiên bản 1.2.2 / 1.2.3:**
   - Hiện tại hệ thống đang vận hành phiên bản **`1.2.1`** rất ổn định, đang ghi nhận dữ liệu điều trị thực tế cho 4 máy online (`PF_003`, `PF_005`, `PF_006`, `PF_011`).
   - Có nên tiếp tục duy trì 1.2.1 để đảm bảo tính liên tục của các ca lọc hiện tại, hay cần chuẩn bị cửa sổ bảo trì (Maintenance Window) để nâng cấp lên 1.2.2 hoặc 1.2.3?
2. **Cấu hình Gateway Card mạng Ethernet (`192.168.5.1`):**
   - Hiện tại card Ethernet không có Default Gateway, khiến Windows xếp vào "Unidentified Network / Public Profile".
   - Phía bệnh viện/khoa có thiết bị định tuyến Gateway nội bộ (ví dụ `192.168.5.254` hoặc tương đương) cần cấu hình vào không, hay duy trì card mạng này ở chế độ cô lập LAN không gateway?
3. **Xử lý trạng thái ca lọc treo trên `PF_009` và `PF_010`:**
   - Máy vật lý `PF_009` và `PF_010` hiện đang offline nhưng FSM trạng thái trong DB vẫn là `RECORDING`.
   - Cần giữ nguyên để chờ máy bật lại gửi gói kết thúc, hay cho phép cơ chế timeout của backend tự đóng ca (`CLOSED`) sau một khoảng thời gian không nhận tín hiệu?
