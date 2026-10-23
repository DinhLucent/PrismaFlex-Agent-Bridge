# PrismaFlex 1.2.4 pilot — ICU-B

Nâng cấp từ 1.2.1, management protocol 2, site `prismaflex`, Analyzer bật, DB revision giữ `d4b2a8f91c30`; không đổi schema. Nền 1.2.3 đã sửa timezone chart/monitor. Bản mới:

- Bỏ nút Analysis trong Journal thu gọn và toàn màn hình; Analyzer riêng vẫn còn.
- Tắt Next.js Image Optimization cho ảnh đóng gói, tránh sinh cache ảnh không có trong manifest ký làm lần khởi động sau bị verifier từ chối.
- Service XML của API/Web/Analyzer khai báo WMI; API/Analyzer đợi PostgreSQL cục bộ, Web đợi API. Lần update tiếp theo đồng bộ dependency SCM. Bản 1.2.1 updater cũ cần script `Apply-Startup-Dependencies.ps1` sau chuyển bản đầu tiên.
- Đọc SMBIOS UUID thử lại có giới hạn khi WMI khởi động trễ; vẫn từ chối máy không có định danh hợp lệ.

Không đổi Collector/OIE hoặc mạng gateway. Treatment continuity phụ thuộc queue bền vững/retry của Collector/OIE ở ICU-B. Không cam kết downtime 10 phút hoặc reboot tự động; agent máy đích phải nghiệm thu dữ liệu thật. Xem [hướng dẫn](START-HERE.md) và [bằng chứng/giới hạn](REVIEW.md).
