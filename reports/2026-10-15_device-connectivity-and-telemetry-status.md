# Báo cáo kiểm tra Endpoint & Kết nối máy lọc máu (ICU-B Connect)
**Thời gian thực hiện:** 2026-10-15 11:45:00 (GMT+7)  
**Mục tiêu kiểm tra:** Trả lời nguyên nhân WebApp/Endpoint không hiển thị máy trên Dashboard Live Monitoring.

---

## 1. Kết quả chẩn đoán chính
- **Endpoint API hoạt động bình thường:**
  - Toàn bộ dịch vụ backend (`prismaflex-api` cổng 8000, `prismaflex-web` cổng 3000, `oieservice` Mirth Connect và `PrismaFlexCollectorService`) đều đang chạy ổn định.
  - Các request từ WebApp tới `/api/v1/devices/{device_id}/events`, `/api/v1/treatments/pending-count` và `/api/v1/telemetry` đều trả về HTTP 200 OK.
- **Nguyên nhân không thấy máy nào trên màn hình Live Monitoring:**
  1. **Do dữ liệu cũ (Đúng):** Các gói tin đang được nạp vào backend hiện tại là dữ liệu tồn đọng từ hàng đợi Mirth OIE trong thời gian backend bị gián đoạn trước đó. Backend ghi nhận các gói tin này ở trạng thái `QUEUE_MODE` (độ trễ > 25 giây) để lưu vào hồ sơ điều trị (Journal), không hiển thị lên thẻ Live Monitoring thời gian thực.
  2. **Thực tế tại khoa ICU-B hiện tại:**
     - 6/9 máy (`PF_003`, `PF_004`, `PF_006`, `PF_008`, `PF_009`, `PF_010`) đang **tắt nguồn hoặc ngắt kết nối mạng** (Ping không phản hồi).
     - 3/9 máy (`PF_005`, `PF_007`, `PF_011`) đang **có kết nối mạng** tới Collector (Ping OK, Collector báo CONNECTED), nhưng cả 3 máy này **chưa có ca lọc máu nào đang chạy** (đang ở trạng thái IDLE / Standby chờ bệnh nhân).

---

## 2. Chi tiết tình trạng các máy tại hiện trường

| Tên máy | IP cấu hình | Ping mạng | Trạng thái Collector | Trạng thái ca lọc | Ghi chú |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **PF_003** | `192.168.5.23` | ❌ Offline | RECONNECT_WAIT | Không có ca | Máy tắt / ngắt mạng |
| **PF_004** | `192.168.5.24` | ❌ Offline | RECONNECT_WAIT | Không có ca | Máy tắt / ngắt mạng |
| **PF_005** | `192.168.5.25` | ✅ Online | CONNECTED | IDLE / Standby | Đã kết nối, chờ ca |
| **PF_006** | `192.168.5.26` | ❌ Offline | RECONNECT_WAIT | Ca cũ (17/09) đã đóng | Máy tắt / ngắt mạng |
| **PF_007** | `192.168.5.27` | ✅ Online | CONNECTED | Ca cũ (18/09) đã đóng | Đã kết nối, chờ ca |
| **PF_008** | `192.168.5.28` | ❌ Offline | RECONNECT_WAIT | Không có ca | Máy tắt / ngắt mạng |
| **PF_009** | `192.168.5.29` | ❌ Offline | RECONNECT_WAIT | Không có ca | Máy tắt / ngắt mạng |
| **PF_010** | `192.168.5.30` | ❌ Offline | RECONNECT_WAIT | Ca gần nhất 13/10 | Máy ngắt kết nối lúc 11:31 |
| **PF_011** | `192.168.5.31` | ✅ Online | CONNECTED | IDLE / Standby | Đã kết nối, chờ ca |

---

## 3. Kết luận và Khuyến nghị
- Hệ thống giám sát ICU-B Connect WebApp hoạt động theo cơ chế **thời gian thực (Live Monitoring)**: Thẻ máy chỉ xuất hiện khi máy PrismaFlex thực tế gửi dữ liệu gói tin trực tiếp trong vòng 25-30 giây gần nhất.
- Khi điều dưỡng bật máy và bắt đầu chạy ca lọc máu (CRRT Run) trên các máy thực tế, dữ liệu LIVE sẽ lập tức xuất hiện trên dashboard mà không cần thao tác thêm.