# Bảng nâng cấp Collector — `collector-hf-20261024.1`

Ngày lập: 2026-10-24. Trạng thái: **candidate / chờ xác minh hiện trường**.
Nguồn: [`3c7811a`](https://github.com/DinhLucent/prismaflex-collector-v2/commit/3c7811ada5f95b4978ce04c8f56a26242fc65c67).
Gói phát hành và SHA-256: [hướng dẫn hotfix](../patches/2026-10-24_collector-hf-20261024.1-INSTRUCTIONS.md).

| ID | Ưu tiên | Hiện tượng/giả thuyết | Đã làm | Bằng chứng | Việc còn lại / cửa chặn |
|---|---|---|---|---|---|
| HF-01 | P0 | Poll outbox quét toàn bộ delivery cũ; writer có thể bị kéo dài bởi lịch sử SQLite | Seek bằng index tới watermark mỗi máy; index hàng chờ, candidate và event | 180.000 raw packet / 18.000 delivery: 5 poll rỗng từ ~315 ms còn ~1–3 ms trên máy dev | Đo startup và poll trên bản sao DB thực tế; không suy luận nguyên nhân NTFS từ benchmark |
| HF-02 | P0 | Dọn dữ liệu lâu có thể giữ writer | Tối đa 256 bản ghi mỗi bảng trong một lượt, tiếp tục ở poll kế | Regression kiểm tra giới hạn và giữ delivery chưa xử lý/watermark | Đo thời gian drain với kích thước và chính sách retention thực tế |
| HF-03 | P0 | SCM RUNNING nhưng status STALE/queue đứng | Heartbeat độc lập 1 giây, command age/native thread ID, trạng thái `WRITER_STALLED` sau 30 giây; chờ stop có hạn | Test writer kẹt: status vẫn cập nhật và không ACK giả; 286 test qua | Giám sát ngoài tiến trình cho trường hợp toàn tiến trình/volume status kẹt; thu dump nếu tái hiện |
| HF-04 | P0 | TCP Service CONNECTED nhưng `User fallback` | GUI dùng tuổi **packet hợp lệ từ nguồn được chọn**, hiện lý do fallback và chi tiết từng cổng; Service vẫn ưu tiên khi có chuỗi packet ổn định | Test Service hồi phục dù User xen kẽ; thử 9 máy/18 luồng, 18.009 packet ~32 KB, không thiếu/trùng/hash sai, cả 9 chọn Service | Xác định 3002 thực có packet ở từng máy, reconnect/timeout và mức ổn định; không ép Service chỉ dựa TCP |
| HF-05 | P0 | Nguy cơ stop lỗi rồi mở thêm tiến trình ghi cùng DB | Giữ mutex nếu shutdown lỗi | Test khóa không được nhả sớm | Thử rollback với process bị treo trong phòng thử nghiệm |
| OPS-01 | P0 | Chưa biết mức tải/điểm nghẽn máy ICU-B | Script chỉ đọc 7 mẫu/60 giây, per-port/status/process/socket/dung lượng | Script smoke test 2 mẫu trên file giả lập | Agent hiện trường gửi baseline và post-cutover đã khử định danh |
| OPS-02 | P0 | Nâng cấp dịch vụ khi đang có ca lọc | Backup, kiểm soát một instance, tiêu chí dừng/rollback trong request | Chưa chạy tại hiện trường | Cửa sổ bảo trì hoặc kế hoạch duy trì dữ liệu được quản trị hiện trường chấp thuận |
| GATE-01 | P1 | Chưa thể hứa hẹn zero loss với buffer hữu hạn | Giữ ACK sau commit; kiểm thử packet duy nhất và hash | 18.009/18.009 giả lập trong 23 giây; quick_check=ok | Soak 72 giờ, reboot/logout/crash, field load, đối chiếu sequence 7 ngày: `NOT_EXECUTED` |

Ảnh và báo cáo ở thời điểm khác nhau không thể chứng minh cùng một nguyên nhân.
`PageIn`, LiveKernelEvent và GIL cần log/dump có thời điểm khớp; `Connected`
chỉ là TCP, còn Service được chọn theo packet đã đóng khung và chính sách hồi phục.
`0 of 9` khi status cũ là tín hiệu dữ liệu giám sát đã mất hiệu lực, không được
dùng làm số máy đang thu thực tế.
