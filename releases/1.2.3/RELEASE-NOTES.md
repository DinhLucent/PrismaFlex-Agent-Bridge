# PrismaFlex 1.2.3 — thay thế bản bàn giao 1.2.2

Sửa nhãn trục/tooltip chart, giờ nhận/sự kiện và Machine Time trên monitor theo giờ Việt Nam, độc lập timezone trình duyệt. Cùng dữ liệu đã tái hiện lệch 7 giờ trên 1.2.2; test nhãn trục/Machine Time pass ở UTC và Việt Nam với 1.2.3.

API/Analyzer/updater và schema giữ nguyên; 134 tệp backend/runtime đối chiếu không đổi byte. Gói được ký lại với version 1.2.3; verifier 1.2.1 chấp nhận chữ ký.

- 253 treatment contracts strict PASS trên PostgreSQL disposable.
- 1 dump/restore PostgreSQL thật PASS.
- 4 browser E2E trên production web build PASS; 10 time/chart helper test PASS.
- 2 standalone proxy probes PASS; audit 1.652 tệp PASS.

[Agent bắt đầu tại đây](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/blob/main/releases/1.2.3/START-HERE.md). Có hướng dẫn online/offline, preflight/postflight, update/recovery, cài mới/license và mẫu báo cáo.

Đây vẫn là prerelease cần nghiệm thu Windows Service và dữ liệu thực tế trên máy đích. Chưa chạy 100.000 gói/soak 60 phút; burst trước đó vượt SLO. Giai đoạn đầu chấp nhận treatment gián đoạn qua update nhưng không tự duyệt/hoàn tất/xóa ca.
