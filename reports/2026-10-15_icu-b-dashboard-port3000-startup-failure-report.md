# Báo cáo Điều tra & Xử lý: Dashboard WebApp (Cổng 3000) Bị Tắt Sau Khởi Động

- **Ngày thực hiện**: 2026-10-15
- **Môi trường**: Máy chủ ICU-B - Bệnh viện Chợ Rẫy (IP: `192.168.5.1`)
- **Dịch vụ mục tiêu**: Dashboard chính ICU-B Connect WebApp (Cổng `3000`)
- **Trạng thái sau xử lý**: **HOÀN TOÀN KHẮC PHỤC - TẤT CẢ SERVICES BẢN MỚI 1.2.1 ĐANG RUNNING & HEALTHY**

---

## 1. Tóm tắt Hiện trạng & Xác nhận từ Quản trị viên

1. **Xác nhận phiên bản**:
   - `icub-frontend` và `icub-backend` trong thư mục `D:\Block\CentralConnect` là **phiên bản cũ** (v3.7.13 chạy qua PM2).
   - Phiên bản mới chính thức là **PrismaFlex Web Platform v1.2.1** cài đặt tại `C:\PrismaFlex` (chạy dạng Windows Services).

2. **Nguyên nhân cốt lõi khiến bản mới bị tắt sau khi khởi động máy**:
   - Windows Service của bản mới (`prismaflex-web`, `prismaflex-api`, `prismaflex-analyzer`) có cơ chế kiểm tra tính toàn vẹn phát hành (`verify-release`) so với `release.manifest.json`.
   - Tính năng Image Optimization của Next.js khi hoạt động đã tự tạo runtime cache `.webp` vào:
     `C:\PrismaFlex\releases\1.2.1\web\.next-protected-release\cache\images\...`
   - Khi máy tính khởi động lại, `prismaflex.exe` quét thấy file này nằm ngoài manifest đã ký số -> Báo lỗi `Manifest integrity failure: Unexpected release file outside signed inventory` và dừng dịch vụ.
   - Trong khi đó, bản cũ `icub-frontend` trong PM2 chỉ chạy khi có người đăng nhập Windows và mất 1 - 5.5 phút mới mở cổng 3000.

---

## 2. Các hành động kỹ thuật đã thực hiện

1. **Dọn dẹp bản cũ khỏi PM2**:
   - Đã dừng và xóa hoàn toàn `icub-frontend` và `icub-backend` khỏi danh sách tiến trình PM2:
     ```powershell
     pm2 stop icub-frontend icub-backend
     pm2 delete icub-frontend icub-backend
     pm2 save
     ```
   - Giữ nguyên tiến trình `dsh` trong PM2 để duy trì kênh kết nối quản trị.
   - Giải phóng hoàn toàn cổng 3000 và 8000.

2. **Dọn dẹp cache & Tạo cơ chế phòng ngừa tự động**:
   - Đã xóa sạch thư mục cache runtime trong `releases\1.2.1\web\.next-protected-release\cache`.
   - Xác thực lại toàn bộ 1.652 file của bản release 1.2.1: Đạt kết quả `status: valid` 100%.
   - Tạo script bảo trì `C:\PrismaFlex\service\cleanup-cache.cmd`.
   - Đăng ký Windows Scheduled Task: `PrismaFlex-CleanCache-Startup` chạy dưới quyền `SYSTEM` tại sự kiện Boot (`AtStartup`), tự động dọn sạch thư mục cache trước khi `prismaflex-web` khởi động (vốn có cấu hình `delayedAutoStart`), đảm bảo dịch vụ luôn khởi chạy thành công sau mọi lần reboot.

3. **Kích hoạt toàn bộ Windows Services của bản mới (`C:\PrismaFlex`)**:
   - Đã khởi động theo thứ tự chuẩn:
     1. `prismaflex-api` (Cổng 8000) -> Running
     2. `prismaflex-analyzer` (Cổng 15555) -> Running
     3. `prismaflex-web` (Cổng 3000) -> Running
     4. `PrismaFlexCollectorService` -> Running

---

## 3. Kết quả nghiệm thu thực tế

Kiểm tra trực tiếp các endpoint sức khỏe hệ thống:
- **API Ready Endpoint** (`http://127.0.0.1:8000/internal/ready`):
  - `status`: `ready`
  - `version`: `1.2.1`
  - `schema_revision`: `d4b2a8f91c30`
- **Analyzer Health Endpoint** (`http://127.0.0.1:15555/health`):
  - `status`: `ok`
- **Dashboard WebApp Cổng 3000** (`http://127.0.0.1:3000/login` & `http://192.168.5.1:3000/login`):
  - `HTTP Status`: **200 OK**
  - Giao diện đăng nhập và giám sát tải tức thì, không có độ trễ.
