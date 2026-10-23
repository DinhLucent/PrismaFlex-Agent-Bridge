# PrismaFlex 1.2.4 pilot — ICU-B

Nâng cấp từ 1.2.1, management protocol 2, site `prismaflex`, Analyzer bật, DB revision giữ `d4b2a8f91c30`; không đổi schema. Nền 1.2.3 đã sửa timezone chart/monitor. Bản mới:

- Bỏ nút Analysis trong Journal thu gọn và toàn màn hình; Analyzer riêng vẫn còn.
- Tắt Next.js Image Optimization cho ảnh đóng gói, tránh sinh cache ảnh không có trong manifest ký làm lần khởi động sau bị verifier từ chối.
- Service XML của API/Web/Analyzer khai báo WMI; API/Analyzer đợi PostgreSQL cục bộ, Web đợi API. Lần update tiếp theo đồng bộ dependency SCM. Bản 1.2.1 updater cũ cần script `Apply-Startup-Dependencies.ps1` sau chuyển bản đầu tiên.
- Đọc SMBIOS UUID thử lại có giới hạn khi WMI khởi động trễ; vẫn từ chối máy không có định danh hợp lệ.

Không đổi Collector/OIE hoặc mạng gateway. Theo yêu cầu chủ máy, hướng dẫn vận hành trên Agent Bridge [bỏ bước Mirth](MIRTH-SKIP-ADDENDUM.md); ZIP đã ký giữ nguyên, còn tài liệu nằm trong ZIP có thể chứa điều kiện Mirth cũ. Treatment giữ ID và ghi tiếp phải nghiệm thu trên máy đích; do không kiểm queue/retry Mirth, **không khẳng định không mất gói lúc API dừng**. Không cam kết downtime 10 phút hoặc reboot tự động. Xem [hướng dẫn hiện hành](START-HERE.md) và [bằng chứng/giới hạn](REVIEW.md).
