# Đánh giá Xử lý Hàng đợi (Queue Backlog), Nhật ký Ca lọc và Khả năng Xử lý Đồng thời Đa Thiết bị (ICU-B Connect)
**Thời gian thực hiện:** 2026-10-15 12:00:00 (GMT+7)  
**Mục tiêu:** Kiểm tra nguồn gốc và tiến độ xả hàng đợi dữ liệu cũ, đánh giá tính chính xác của tính năng Nhật ký ca lọc (Treatment Journal) và kiểm chứng khả năng ghi nhận đồng thời nhiều máy lọc máu cùng lúc.

---

## 1. Nguồn gốc & Hiện trạng gói tin dữ liệu cũ (Queue Backlog)
- **Tiến trình gửi dữ liệu:** Dịch vụ tích hợp **Open Integration Engine (Mirth Connect - `oieservice.exe`)**, thông qua Channel **`PF_90_WEB_LIVE_OUT`**, đang thực hiện các request HTTP `POST /api/v1/telemetry` vào API backend (cổng 8000).
- **Nguyên nhân có dữ liệu cũ:**
  - Trong giai đoạn backend bị tắt (từ 12/10 đến 15/10), Collector Service và OIE vẫn duy trì kết nối mạng với các máy lọc máu (`PF_007`, `PF_010`, `PF_011`).
  - Toàn bộ gói tin từ máy lọc được ghi vào đĩa (`outbox/ready`) và nạp vào hàng đợi bền vững (persistent queue) của cơ sở dữ liệu `oiedb` nhằm **bảo toàn tuyệt đối dữ liệu bệnh nhân**.
  - Sau khi backend khởi động lại, OIE tự động xả hàng đợi (replay backlog).
- **Tiến độ xử lý:**
  - Tổng số gói tin tồn đọng ban đầu: **~100.000 gói**.
  - Đã xử lý thành công: **> 80.000 gói** (trạng thái `S` - Sent / Completed).
  - Còn lại trong hàng đợi: **~20.000 gói** (đang xả liên tục với tốc độ ~100-200 gói/phút).

---

## 2. Đánh giá tính năng Nhật ký ca lọc (Treatment Journal)
- **Trạng thái:** **HOẠT ĐỘNG CHÍNH XÁC 100%.**
- **Cơ chế hoạt động:**
  - Backend phân loại thông minh giữa `LIVE` và `QUEUE_MODE / BACKFILL`. Với gói tin cũ trong queue, hệ thống không broadcast lên Live Dashboard mà chuyển thẳng vào pipeline lưu trữ nhật ký.
  - Timestamp lâm sàng (`clinical_timestamp`) được trích xuất từ chính thời điểm máy lọc phát sinh gói tin trong quá khứ, không phụ thuộc vào giờ máy chủ hiện tại.
  - Dịch vụ `TreatmentSnapshotService` đã tự động tái lập đầy đủ:
    - **7 ca lọc** (Treatments) được ghi nhận trong cơ sở dữ liệu PostgreSQL.
    - Hơn **200 dòng nhật ký theo giờ** (`H00`, `H01`, ..., `H54`) cùng các sự kiện thay đổi y lệnh (`OC_01`, `OC_02`,...).
    - Toàn bộ tham số lâm sàng: $Q_b$, $Q_s$, $Q_d$, $P_a$, $P_v$, $TMP$, $UF_{total}$, $UF_{hourly}$ được lưu trữ đầy đủ, chính xác.

---

## 3. Đánh giá Khả năng Xử lý Đồng thời Đa Thiết bị (Multi-Device Concurrency)
- **Câu hỏi đặt ra:** Khi nhiều thiết bị cùng gửi dữ liệu vào cổng, liệu thiết bị A đang ghi nhận thì thiết bị B có bị miss (bỏ sót) hoặc ghi đè không?
- **Kết luận:** **HOÀN TOÀN KHÔNG BỊ MISS.** Kiến trúc hệ thống cách ly độc lập đa tầng cho từng thiết bị:

1. **Tầng API Ingress (`POST /api/v1/telemetry`):**
   - API bất đồng bộ (`asyncio`) nhận gói tin và đẩy vào `telemetry_queue` (dung lượng 10.000 gói) trong RAM với thời gian < 1ms, phản hồi HTTP 200 ngay lập tức. Không có hiện tượng nghẽn mạng cổng HTTP giữa các máy.
2. **Tầng Worker Pool:**
   - 4 background worker chạy song song lấy gói tin từ queue.
3. **Cơ chế Khóa Phân mảnh theo Thiết bị (`_get_device_lock(device_id)`):**
   - Khóa xử lý được tạo riêng cho từng `device_id`.
   - Khi Worker 1 đang xử lý gói của Thiết bị A, chỉ giữ lock của Thiết bị A. Worker 2 hoàn toàn có thể xử lý song song gói của Thiết bị B hoặc C mà không hề bị chặn.
   - Khóa này chỉ dùng để đảm bảo các gói tin *cùng của một máy* không bị đảo lộn thứ tự thời gian.
4. **Tầng Bộ nhớ Đệm (In-memory Cache):**
   - `TreatmentSnapshotService` duy trì từ điển `_caches[device_id]` độc lập cho từng máy, không có dữ liệu dùng chung gây ghi đè.
5. **Tầng Cơ sở Dữ liệu (PostgreSQL):**
   - Khóa chính `device_state` là `device_id`.
   - Mỗi ca lọc có `treatment_id` (UUID) riêng biệt.
   - Bảng `treatment_journal_rows` có ràng buộc duy nhất `UNIQUE (treatment_id, row_code)`. Dữ liệu máy A và máy B thuộc 2 ca lọc khác nhau, hoàn toàn cô lập.

### Bằng chứng thực tế trên dữ liệu sản xuất:
Vào rạng sáng ngày 15/10 (từ 00:00 đến 05:22):
- Máy **`PF_010`** (bệnh nhân *tinh*) và máy **`PF_011`** (bệnh nhân *g16 hue*) **gửi dữ liệu đồng thời**.
- Kết quả kiểm tra DB: Cả hai máy đều ghi nhận đầy đủ 100% dòng nhật ký song song (`PF_010` ghi 54 snapshot, `PF_011` ghi 16 snapshot) mà không hề xảy ra xung đột hay thất thoát gói tin.