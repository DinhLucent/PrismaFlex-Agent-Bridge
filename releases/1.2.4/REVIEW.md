# Kiểm chứng chủ phát hành — 24/10/2026

| Phạm vi | Kết quả |
|---|---|
| Release test suite | 114 PASS, 1 SKIP; gồm dependency WMI/PostgreSQL/API và retry UUID |
| PostgreSQL treatment contracts chọn lọc | 22 PASS trên DB disposable; 4 case gián đoạn 10/15 phút, có/không replay, giữ ID/start time/H00 rồi ghi tiếp H01, retry không nhân đôi raw/receipt |
| Frontend | TypeScript, production build, time/chart helpers 10 PASS; ESLint không lỗi (16 warning có sẵn) |
| Browser production smoke | Trang/login/logo chạy; image optimizer không dùng, không sinh cache ảnh |
| Windows updater | State-machine test mock 10 PASS; chưa chạy updater thực tế tại ICU-B |

Các case local không chứng minh Collector/OIE ở ICU-B đã lưu đủ mọi gói trong thời gian API ngừng. Chưa thử reboot sau khi chỉnh dependency ngày 23/10, chưa đo thời gian backup DB thật, chưa chứng minh tải 100.000 gói/soak 60 phút. Báo cáo startup ngày 23/10 trong Bridge ghi boot gần nhất ngày 18/10. Báo cáo `reports/2026-10-23_startup-gateway-disconnection-and-port3000-remediation.md` hiện chỉ có BOM; dùng báo cáo audit toàn diện cùng ngày để đối chiếu, không xem file rỗng đó là bằng chứng.

Gói ZIP phải được kiểm bởi verifier 1.2.1, SHA-256 và chữ ký trước khi cài; kết quả phát hành cụ thể nằm trong `ARTIFACT.json` và `PACKAGE-INFO.json`. Chỉ agent ICU-B có thể xác nhận treatment thực, backlog, gateway và startup sau reboot.
