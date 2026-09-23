# PrismaFlex Agent Bridge

Kênh giao tiếp đồng bộ giữa 2 thiết bị và các Agent quản trị hệ thống PrismaFlex.

## Bàn giao mới: PrismaFlex 1.2.2

Agent máy đích bắt đầu tại [bộ cài và hướng dẫn 1.2.2](releases/1.2.2/START-HERE.md).
Đây là bản ứng viên cần nghiệm thu update, thời gian, chart và journal tại máy đích.

## Cấu trúc thư mục

- `requests/`: Chứa các yêu cầu, chỉ thị, prompt hoặc task cần gửi và xử lý giữa các thiết bị / Agent.
- `reports/`: Chứa các báo cáo kết quả triển khai, cập nhật trạng thái hệ thống, log kiểm tra sau bảo trì hoặc vá lỗi.

## Quy trình giao tiếp

1. **Gửi yêu cầu (Request)**: Tạo file markdown hoặc json trong thư mục `requests/`, mô tả mục tiêu và nội dung cần thực thi.
2. **Thực thi & Báo cáo (Report)**: Agent/Thiết bị nhận nhiệm vụ thực hiện và tạo báo cáo trong thư mục `reports/`.
3. **Đồng bộ**: Commit và push lên GitHub remote repository `origin/main` để thiết bị kia cập nhật.
