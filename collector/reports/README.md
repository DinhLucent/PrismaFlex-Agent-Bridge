# Collector Reports (Target Agent -> Dev Agent)

Thư mục này chứa các báo cáo nghiệm thu, log đo đạc socket, metrics kiểm tra hàng đợi, kết quả chạy script chẩn đoán hoặc báo cáo sự cố được gửi từ **Target Agent** (ICU-B) về **Dev Agent**.

## Quy chuẩn đặt tên file

- Định dạng: `YYYY-MM-DD_<tieu-de-bao-cao>.md`
- Ví dụ: `2026-10-24_collector-baseline-assessment.md`

## Nguyên tắc An toàn Dữ liệu (De-identification)

- Tuyệt đối **KHÔNG** đính kèm:
  - Tên hoặc số định danh bệnh nhân thật (Patient ID).
  - Khóa bản quyền phần cứng (Hardware License Key / UUID).
  - Dữ liệu thô lâm sàng nhạy cảm.
  - Mật khẩu hoặc token xác thực.
- Chỉ báo cáo các số liệu kỹ thuật: Trạng thái service, socket connection state, packet counter, latency, queue backlog, lỗi kết nối.
