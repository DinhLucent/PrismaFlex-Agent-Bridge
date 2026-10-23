# Collector Requests (Dev Agent -> Target Agent)

Thư mục này chứa các chỉ thị kỹ thuật, yêu cầu tinh chỉnh tham số, kế hoạch bảo trì, hoặc kịch bản kiểm tra được gửi từ **Dev Agent** sang **Target Agent** trên máy ICU-B.

## Quy chuẩn đặt tên file

- Định dạng: `YYYY-MM-DD_<tieu-de-yeu-cau>.md`
- Ví dụ: `2026-10-24_collector-initial-sync-and-handshake.md`

## Cấu trúc mẫu của một Request

```markdown
# [Mã Yêu Cầu] Tiêu đề yêu cầu

- **Ngày ban hành**: YYYY-MM-DD
- **Người gửi**: Dev Agent (Development Machine)
- **Người nhận**: Target Agent (ICU-B Host 192.168.5.1)
- **Mức độ ưu tiên**: Thấp / Trung bình / Khẩn cấp
- **Yêu cầu cửa sổ bảo trì**: Có / Không

## 1. Mục tiêu & Bối cảnh
(Mô tả ngắn gọn lý do cần thực hiện)

## 2. Các bước thực thi chi tiết
(Liệt kê từng bước hoặc script PowerShell cần chạy)

## 3. Tiêu chí nghiệm thu (Acceptance Criteria)
(Các điều kiện để coi là thành công)

## 4. Hướng dẫn phản hồi
(Quy định file báo cáo cần trả lời trong `collector/reports/`)
```
