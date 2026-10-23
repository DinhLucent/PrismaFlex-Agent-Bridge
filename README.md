# PrismaFlex Agent Bridge

Kênh giao tiếp đồng bộ hai chiều giữa hai thiết bị và các Agent quản trị hệ thống PrismaFlex:
- **Dev Agent**: Máy phát triển (Development & Architecture Control)
- **Target Agent**: Máy trạm lâm sàng ICU-B Bệnh viện Chợ Rẫy (Host IP: `192.168.5.1`)

---

## 1. Không gian Làm việc Chuyên biệt (Subsystem Workspaces)

### 📌 `collector/` — Phân hệ PrismaFlex Collector
Không gian làm việc và kênh trao đổi kỹ thuật riêng biệt cho dịch vụ thu nhận dữ liệu thô `PrismaFlexCollectorService` (v2):
- **Giao tiếp hai chiều**: Trao đổi chỉ thị, yêu cầu tinh chỉnh tham số (timeout, keepalive, buffer retention), kịch bản test và bản vá khẩn cấp giữa Dev Agent và Target Agent.
- **Giám sát thời gian thực**: Theo dõi ma trận kết nối 11 máy lọc PrismaFlex (`PF_001` - `PF_011`), socket ports 3001 & 3002, cơ sở dữ liệu SQLite WAL và hàng đợi chuyển tiếp OIE Mirth Connect.
- **An toàn lâm sàng**: Đảm bảo không làm gián đoạn ca điều trị đang diễn ra (`IN_PROGRESS`), không xung đột tài nguyên và bảo toàn 100% dữ liệu telemetry.
- Chi tiết xem tại: [`collector/README.md`](collector/README.md) và bảng trạng thái [`collector/STATUS.md`](collector/STATUS.md).

---

## 2. Quản lý Phiên bản Phát hành (System Releases)

- **Bản phát hành ứng viên 1.2.4**: [Hướng dẫn và bộ cài 1.2.4](releases/1.2.4/START-HERE.md) — Sửa lỗi phụ thuộc dịch vụ khởi động cổng 3000, kiểm tra SMBIOS UUID và dọn dẹp cache.
- **Bản phát hành 1.2.3**: [Hướng dẫn 1.2.3](releases/1.2.3/START-HERE.md) — Bản cập nhật chuẩn hóa timezone cho monitor và biểu đồ.
- **Bản đang hoạt động thực tế tại ICU-B**: `1.2.1` (phục vụ điều trị lâm sàng liên tục).

---

## 3. Cấu trúc Thư mục Toàn hệ thống

- `collector/`: Không gian làm việc chuyên trách cho phân hệ PrismaFlex Collector.
- `requests/`: Chứa các yêu cầu, chỉ thị cấp hệ thống chung giữa các thiết bị / Agent.
- `reports/`: Chứa các báo cáo rà soát hệ thống tổng thể, nhật ký kiểm tra sau bảo trì.
- `releases/`: Tài liệu hướng dẫn cài đặt, nghiệm thu và metadata các bản phát hành.
- `installers/`: Thư mục lưu trữ bộ cài nhị phân (phân phối qua GitHub Release assets).
- `data/`: Dữ liệu telemetry, file cấu hình và cơ sở dữ liệu mẫu từ hiện trường phục vụ kiểm chứng.

---

## 4. Quy trình Giao tiếp Agent-to-Agent (A2A)

1. **Gửi yêu cầu (Request)**: Tạo file markdown trong `collector/requests/` (cho Collector) hoặc `requests/` (cho toàn hệ thống), mô tả rõ mục tiêu, tham số tinh chỉnh và tiêu chí nghiệm thu.
2. **Thực thi & Kiểm tra (Inspect & Execute)**: Target Agent tiếp nhận chỉ thị qua `git pull`, chạy các script kiểm tra/tinh chỉnh trong môi trường an toàn lâm sàng.
3. **Báo cáo & Cập nhật (Report & Status)**: Target Agent tổng hợp số liệu đã khử định danh vào `collector/reports/`, cập nhật bảng trạng thái `collector/STATUS.md`.
4. **Đồng bộ hóa (Sync)**: Commit và push lên GitHub remote repository `origin/main` để hai bên đồng bộ trạng thái tức thời.
