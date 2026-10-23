# Báo cáo Dữ liệu Đo xa & Hiện trạng Hoạt động Collector (ICU-B)

- **Thời điểm trích xuất**: 2026-10-24 02:07:06 (GMT+7)
- **Thiết bị thực hiện**: Máy chủ trạm ICU-B Chợ Rẫy (`192.168.5.1`)
- **Tình trạng Dịch vụ Windows**: `Running` (PID: `6932`, RAM: `135.93 MB`)
- **Thời gian khởi động**: `2026-10-23 14:08:40` (Uptime: `0.50` ngày)

---

## 1. Chỉ số Tổng quan Hệ thống (System Aggregates)

| Chỉ số | Giá trị ghi nhận | Đánh giá |
|---|---|---|
| **Tổng số gói tin đã lưu (Committed)** | 54,652 gói | Tích lũy liên tục |
| **Tổng dung lượng mạng đã nạp** | 101,179,424 bytes | Luồng TCP 3001/3002 |
| **Độ sâu hàng đợi bộ ghi (Writer Queue)** | 5 / 4096 | Khả năng đáp ứng đĩa |
| **Dung lượng Database SQLite** | 3089.75 MB | WAL Mode an toàn |
| **Kích thước file WAL hiện thời** | 25.67 MB | Cơ chế checkpoint tự động |
| **Hàng đợi Outbox Chuyển tiếp OIE** | 0 files tồn đọng | 0 phút (Sạch hàng đợi) |

---

## 2. Kết nối Mạng & Socket Thực tế

- **Cổng User 3001**: Lắng nghe: `False` | Kết nối Established: `4`
- **Cổng Service 3002**: Lắng nghe: `False` | Kết nối Established: `1`

### Ma trận Ping 11 Máy lọc PrismaFlex
| Máy lọc | Địa chỉ IP | Kết quả Ping |
|:---:|:---:|:---:|
| PF_001 | 192.168.5.21 | OFFLINE |
| PF_002 | 192.168.5.22 | OFFLINE |
| PF_003 | 192.168.5.23 | ONLINE |
| PF_004 | 192.168.5.24 | OFFLINE |
| PF_005 | 192.168.5.25 | ONLINE |
| PF_006 | 192.168.5.26 | ONLINE |
| PF_007 | 192.168.5.27 | OFFLINE |
| PF_008 | 192.168.5.28 | OFFLINE |
| PF_009 | 192.168.5.29 | OFFLINE |
| PF_010 | 192.168.5.30 | OFFLINE |
| PF_011 | 192.168.5.31 | ONLINE |


---

## 3. Trạng thái Chi tiết Các Kênh Socket Thiết bị (Từ Collector Engine)

| Thiết bị | Port | Socket State | Reconnects | Gói tin | Lỗi gần nhất | Thời điểm gói cuối (UTC) |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| PF_010 | Port 3001 | RECONNECT_WAIT | 635 | 0 | TIMEOUTERROR |  |
| PF_010 | Port 3002 | RECONNECT_WAIT | 633 | 0 | TIMEOUTERROR |  |
| PF_011 | Port 3001 | CONNECTED | 0 | 4276 |  | 2026-10-23T19:03:30.931601Z |
| PF_011 | Port 3002 | CONNECTED | 309 | 0 |  |  |
| PF_003 | Port 3001 | CONNECTED | 0 | 4275 |  | 2026-10-23T19:03:21.382243Z |
| PF_003 | Port 3002 | CONNECTED | 15 | 33863 |  | 2026-10-23T19:03:21.052782Z |
| PF_004 | Port 3001 | RECONNECT_WAIT | 616 | 0 | TIMEOUTERROR |  |
| PF_004 | Port 3002 | RECONNECT_WAIT | 627 | 0 | TIMEOUTERROR |  |
| PF_005 | Port 3001 | CONNECTED | 44 | 4000 |  | 2026-10-23T19:03:21.628726Z |
| PF_005 | Port 3002 | CONNECTED | 264 | 4020 |  | 2026-10-23T10:03:52.810232Z |
| PF_006 | Port 3001 | CONNECTED | 12 | 4218 |  | 2026-10-23T19:03:30.315926Z |
| PF_006 | Port 3002 | RECONNECT_WAIT | 646 | 0 | TIMEOUTERROR |  |
| PF_007 | Port 3001 | CONNECTING | 611 | 0 | TIMEOUTERROR |  |
| PF_007 | Port 3002 | RECONNECT_WAIT | 633 | 0 | TIMEOUTERROR |  |
| PF_008 | Port 3001 | CONNECTING | 637 | 0 | TIMEOUTERROR |  |
| PF_008 | Port 3002 | RECONNECT_WAIT | 622 | 0 | TIMEOUTERROR |  |
| PF_009 | Port 3001 | RECONNECT_WAIT | 661 | 0 | TIMEOUTERROR |  |
| PF_009 | Port 3002 | RECONNECT_WAIT | 629 | 0 | TIMEOUTERROR |  |


---

## 4. Trích đoạn Nhật ký Hệ thống Gần nhất (Logs Tail)

```text
2026-10-23T18:47:07Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:47:59Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:48:14Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:48:25Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:48:46Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:49:02Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:49:08Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:49:33Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=3 source_port=3002 error_code=CONNECTIONRESETERROR suppressed_events=1
2026-10-23T18:49:45Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:50:39Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=6 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:50:51Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=11 source_port=3002 error_code=SILENT_CONNECTION_TIMEOUT suppressed_events=2
2026-10-23T18:51:08Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:51:57Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:52:37Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=5 source_port=3002 error_code=TIMEOUTERROR suppressed_events=2
2026-10-23T18:52:49Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:53:39Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:53:54Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:54:18Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:54:32Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:54:40Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:54:57Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:55:29Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:56:12Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=6 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:56:28Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=11 source_port=3002 error_code=TIMEOUTERROR suppressed_events=2
2026-10-23T18:56:33Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:57:36Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:58:31Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:59:19Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:59:34Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T18:59:59Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=5 source_port=3002 error_code=SILENT_CONNECTION_TIMEOUT suppressed_events=2
2026-10-23T19:00:10Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:00:18Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:00:18Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:00:47Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:01:12Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:01:32Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=3 source_port=3002 error_code=CONNECTIONRESETERROR suppressed_events=1
2026-10-23T19:01:45Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=6 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:01:59Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:03:15Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:04:14Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:04:24Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=11 source_port=3002 error_code=SILENT_CONNECTION_TIMEOUT suppressed_events=2
2026-10-23T19:04:59Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:05:14Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=10 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:05:55Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:06:02Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=7 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:06:04Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=8 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:06:36Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:06:56Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=4 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:07:18Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=6 source_port=3002 error_code=TIMEOUTERROR suppressed_events=4
2026-10-23T19:07:24Z level=WARNING logger=prismaflex.collector.port_session event=port_unavailable device_id=9 source_port=3001 error_code=TIMEOUTERROR suppressed_events=4
```

---

## 5. Kết luận cho Dev Agent
- Dữ liệu cấu hình đã được copy vào: `collector/configs/collector_service.active.json`
- Mọi thông số thu thập được tuân thủ nguyên tắc không chứa thông tin cá nhân bệnh nhân.
