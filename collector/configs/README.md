# Collector Configurations

Thư mục này chứa các file cấu hình mẫu và hướng dẫn tinh chỉnh cho phân hệ PrismaFlex Collector.

## Danh mục tài liệu

- `collector_service.template.json`: Template chuẩn cấu hình dịch vụ `PrismaFlexCollectorService` (v2), định nghĩa 11 thiết bị máy lọc PrismaFlex tại ICU-B, tham số mạng, và chính sách lưu trữ SQLite.
- `devices.map.json`: Danh mục đối chiếu 11 máy lọc PrismaFlex (Device ID, mã máy `PF_001` - `PF_011`, IP tĩnh, cổng User 3001 / Service 3002, số giường).
- `tuning_parameters.md`: Giải thích chi tiết ý nghĩa từng tham số và hướng dẫn ngưỡng giá trị tối ưu cho điều kiện lâm sàng thực tế.
