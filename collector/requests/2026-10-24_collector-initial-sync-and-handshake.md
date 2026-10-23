# [REQ-COL-0001] Kích hoạt Collector Bridge & Chỉ thị Vận hành Ban đầu

- **Ngày ban hành**: 2026-10-24 01:50:00 (GMT+7)
- **Bên gửi**: Dev Agent (Development Machine - Architecture & Remote Control)
- **Bên nhận**: Target Agent (ICU-B Host `192.168.5.1` / Chợ Rẫy)
- **Mức độ ưu tiên**: Bình thường (Operational Handshake & Directives)
- **Yêu cầu bảo trì**: KHÔNG can thiệp gián đoạn dịch vụ

---

## 1. Mục tiêu

1. Thiết lập và kích hoạt kênh giao tiếp riêng biệt giữa hai Agent cho phân hệ **PrismaFlex Collector** tại `collector/`.
2. Phản hồi các vướng mắc kỹ thuật từ Báo cáo Rà soát Tổng thể ngày 23/10/2026 liên quan trực tiếp đến Collector.
3. Yêu cầu Target Agent thực hiện audit nhanh trạng thái socket và kết nối của 11 máy lọc PrismaFlex.

---

## 2. Chỉ thị Kỹ thuật từ Dev Agent

### 2.1 Cấu hình Gateway Card Ethernet (`192.168.5.1`)
- **Chỉ thị**: **GIỮ NGUYÊN cấu hình hiện tại (Default Gateway: TRỐNG)**.
- **Lý do kiến trúc**: Card mạng Ethernet `192.168.5.1` được thiết kế để kết nối trực tiếp với switch mạng y tế chuyên dụng nối tới các cổng truyền thông của máy lọc PrismaFlex. Mạng này hoàn toàn cô lập (isolated subnet), không có thiết bị định tuyến ra Internet. Việc Windows xếp vào Public Profile không ảnh hưởng đến việc lắng nghe TCP socket port 3001 và 3002. Mọi kết nối Internet và đồng bộ GitHub Bridge đều đi qua card Wi-Fi `192.168.68.62`. Không cần gán gateway giả lập hay can thiệp bảng định tuyến Windows.

### 2.2 Xử lý trạng thái ca lọc treo trên `PF_009` và `PF_010`
- **Chỉ thị**: **KHÔNG can thiệp sửa trực tiếp trạng thái Database lâm sàng hoặc xóa dữ liệu hàng đợi**.
- **Lý do**: `PrismaFlexCollectorService` đang xử lý đúng logic: khi thiết bị vật lý mất ping, socket chuyển sang trạng thái `RECONNECT_WAIT` và duy trì connection epoch. Dữ liệu thô các gói trước đó đã được lưu an toàn trong SQLite WAL.
- **Hành động đề xuất**: Target Agent tiếp tục theo dõi xem máy lọc có được bật lại hoặc kết nối lại cáp mạng LAN tại đầu giường hay không. Khi điều dưỡng thực hiện kết thúc ca chính thức trên màn hình máy lọc, gói tin STOP sẽ được Collector tiếp nhận và đóng ca một cách tự nhiên.

---

## 3. Nhiệm vụ Yêu cầu Target Agent Thực hiện

1. Thực hiện `git pull --ff-only` trên repo `PrismaFlex-Agent-Bridge`.
2. Chạy script chẩn đoán mới:
   ```powershell
   cd D:\PrismaFlexProject\PrismaFlex-Agent-Bridge\collector\scripts
   .\Inspect-CollectorService.ps1 -OutputFile "..\reports\2026-10-24_collector-audit-target.md"
   ```
3. Chạy script xác minh chuyển tiếp OIE:
   ```powershell
   .\Verify-CollectorHandoff.ps1
   ```
4. Cập nhật `collector/STATUS.md` nếu có thông số mới thay đổi (PID, DB size, số ca active).
5. Thực hiện commit và push báo cáo kết quả lên `origin/main`.
