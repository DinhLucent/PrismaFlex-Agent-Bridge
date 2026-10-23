# Collector Patches & Emergency Hotfixes

Thư mục này dành riêng cho việc chuyển giao các bản vá nóng (hotfixes), delta patches, script sửa chữa khẩn cấp hoặc các file nhị phân đơn lẻ cho phân hệ PrismaFlex Collector mà không cần chờ đóng gói toàn bộ bộ cài đặt `installers/`.

## Quy trình Phát hành Bản vá

1. **Phía Dev Agent**:
   - Soạn bản vá (ví dụ file `.patch`, script sửa lỗi `.ps1`, hoặc file `.exe` đơn lẻ).
   - Đặt vào thư mục này kèm theo file `YYYY-MM-DD_<ten-ban-va>-INSTRUCTIONS.md` mô tả:
     - Mục đích sửa chữa và mã lỗi khắc phục.
     - Kiểm tra mã băm SHA-256 của file vá.
     - Quy trình backup file cũ trước khi thay thế.
     - Kế hoạch rollback nếu có bất thường.
2. **Phía Target Agent**:
   - Xác thực SHA-256.
   - Dừng dịch vụ an toàn (khi không có ca lọc máu đang chạy hoặc trong cửa sổ bảo trì).
   - Áp dụng bản vá và kiểm tra lại log.
   - Ghi nhận kết quả vào `collector/reports/`.
