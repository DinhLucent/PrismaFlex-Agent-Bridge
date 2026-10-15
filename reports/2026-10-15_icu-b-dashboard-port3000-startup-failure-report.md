# Báo cáo Điều tra: Nguyên nhân Dashboard WebApp (Cổng 3000) Bị Tắt Sau Khởi Động

- **Ngày thực hiện**: 2026-10-15
- **Môi trường**: Máy chủ ICU-B - Bệnh viện Chợ Rẫy (IP: `192.168.5.248`)
- **Dịch vụ mục tiêu**: Dashboard chính ICU-B Connect WebApp (Cổng `3000`)
- **Mã lỗi chính**: `Manifest integrity failure: Unexpected release file outside signed inventory` (Exit code 1) & `ERR_CONNECTION_REFUSED` / User Logon Delay

---

## 1. Tóm tắt Hiện trạng & Hai Luồng Vận hành Chồng chéo

Qua rà soát hệ thống, trên máy chủ đang tồn tại **2 cơ chế quản lý dashboard cổng 3000 chạy song song và cạnh tranh**:

1. **Cơ chế 1 - Windows Service chính thức (`prismaflex-web`)**:
   - Vị trí: `C:\PrismaFlex\service\prismaflex-web.exe`
   - Cấu hình: Windows Service chế độ `Automatic` (Delayed), chạy dưới quyền `LocalSystem`.
   - Cổng mạng đăng ký: `3000` (xem `C:\PrismaFlex\shared\config\runtime.json`: `"WEB_PORT": 3000`).
   - Hiện trạng: **Stopped** (bị tắt hoàn toàn).

2. **Cơ chế 2 - Quản lý tiến trình qua PM2 (`icub-frontend`)**:
   - Vị trí: `D:\Block\CentralConnect\frontend`
   - Cấu hình: Next.js 16.1.6 chạy dưới PM2 daemon (PID: 9724/10620).
   - Cơ chế khởi động: Đăng ký qua Windows Registry Run key của user `Administrator` (`HKCU\...\Run\PM2`), chạy file `pm2_resurrect.cmd` ẩn qua VBScript.
   - Cổng mạng đăng ký: `3000`.

---

## 2. Nguyên nhân Gốc rễ (Root Causes)

### Nguyên nhân 1: Windows Service `prismaflex-web` bị crash ngay khi khởi động máy tính do vi phạm Integrity Check

- **Bằng chứng từ Event Viewer & Log File**:
  - Tại `C:\PrismaFlex\shared\logs\prismaflex-web.err.log`:
    ```
    Manifest integrity failure: Unexpected release file outside signed inventory
    ```
  - Tại `System Event Log` (Event ID 7031, 7034 lúc 08:09:40 - 08:11:14 ngày 18/09/2026 - thời điểm máy tính boot):
    - Dịch vụ `prismaflex-web` tự động khởi động nhưng thoát ngay lập tức (exit code 1).
    - WinSW thực hiện restart tự động 3 lần (mỗi lần cách 30s) nhưng đều thất bại và chuyển hẳn sang trạng thái `Stopped`.
- **Cơ chế gây lỗi (Design Flaw giữa Next.js Image Optimization và PrismaFlex Integrity Scanner)**:
  - Khi `prismaflex.exe` khởi động, cơ chế bảo vệ kiểm tra toàn bộ file trong thư mục release `C:\PrismaFlex\releases\1.2.1` so với danh mục có chữ ký số trong `release.manifest.json` (tổng cộng 1652 file).
  - Trước khi khởi động lại máy, ngày 16/09/2026 lúc 15:38:10, Next.js Image Optimization đã tự động sinh một file ảnh cache `.webp`:
    `C:\PrismaFlex\releases\1.2.1\web\.next-protected-release\cache\images\_iGBW2kDkSTt_s5QbZUZiSHUFwXKemUigWV-ToIHRoA\14400.1789562290543.Y3R9fhXBIgg8zB-crPGEqHWc2naC93qpajEHV5ybGMc.Vy8iOTk2NjYtMWEwOGJjNGRkZDAi.webp`
  - Vì file cache này nằm trực tiếp trong thư mục release nhưng không có tên trong `release.manifest.json`, lệnh `verify-release` của `prismaflex.exe` kết luận là release bị can thiệp trái phép -> **Từ chối khởi chạy và crash toàn bộ service Web, API và Analyzer**.

---

### Nguyên nhân 2: Đối với tiến trình PM2 `icub-frontend`, không khởi chạy được khi chưa đăng nhập và độ trễ khởi động quá lớn

1. **Phụ thuộc vào đăng nhập người dùng (User Logon Dependency)**:
   - PM2 không được cài đặt làm Windows Service. Lệnh `pm2 resurrect` chỉ nằm ở `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
   - Windows của máy chủ hiện **không bật AutoAdminLogon** (`AutoAdminLogon` để trống trong `Winlogon`).
   - **Hậu quả**: Khi máy tính khởi động lại và đứng ở màn hình Login / Lock screen, PM2 hoàn toàn không chạy, cổng 3000 đóng.
2. **Độ trễ biên dịch / khởi động Next.js rất lớn (Startup Latency)**:
   - Theo log `icub-frontend-out-1.log`, Next.js 16 mất từ **60s đến 328.6s (gần 5.5 phút)** mới chuyển sang trạng thái `Ready`:
     ```
     ✓ Starting...
     ✓ Ready in 328.6s
     ▲ Next.js 16.1.6
     - Local: http://localhost:3000
     ```
   - Trong suốt khoảng thời gian 1 - 5 phút này, người dùng mở shortcut Desktop hoặc trình duyệt sẽ lập tức gặp lỗi kết nối `ERR_CONNECTION_REFUSED`, tạo cảm giác WebApp bị tắt hoàn toàn.

---

### Nguyên nhân 3: Xung đột cổng mạng (Port Conflict 3000)

- Cả 2 hệ thống (`prismaflex-web` Windows Service và `icub-frontend` PM2) đều được cấu hình chiếm dụng cổng `3000`.
- Nếu Windows Service được sửa lỗi và chạy đúng, tiến trình PM2 khi đăng nhập vào sẽ báo lỗi `EADDRINUSE` và crash liên tục.

---

## 3. Giải pháp Khắc phục Triệt để

1. **Khắc phục lỗi Integrity của Windows Service `C:\PrismaFlex`**:
   - Xóa file runtime cache nằm ngoài manifest:
     `Remove-Item -Recurse -Force "C:\PrismaFlex\releases\1.2.1\web\.next-protected-release\cache"`
   - Điều chỉnh cấu hình Next.js hoặc script khởi chạy để thư mục cache nằm ngoài thư mục `releases\1.2.1` (ví dụ chuyển sang `C:\PrismaFlex\shared\cache`), tránh việc runtime sinh file làm hỏng chữ ký số.

2. **Chuẩn hóa kiến trúc chạy cổng 3000**:
   - Quyết định dứt khoát dashboard chính do **Windows Service (`prismaflex-web`)** hay **PM2 (`icub-frontend`)** đảm nhiệm:
     - Nếu dùng Windows Service: Tắt `icub-frontend` trong PM2 (`pm2 delete icub-frontend && pm2 save`).
     - Nếu dùng PM2: Đổi `prismaflex-web` sang chế độ `Disabled` hoặc `Manual`, và chuyển PM2 thành Windows Service (sử dụng `pm2-service-install` / NSSM) hoặc bật AutoLogon để tự động chạy khi bật máy mà không cần người dùng đăng nhập.
