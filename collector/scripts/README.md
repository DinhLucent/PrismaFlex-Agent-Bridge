# Collector Operational Scripts

Thư mục này chứa các script PowerShell hỗ trợ Target Agent kiểm tra, đo đạc và chẩn đoán phân hệ Collector trên máy trạm ICU-B.

## 1. `Inspect-CollectorService.ps1`
- **Mục đích**: Chạy một lần để quét toàn bộ trạng thái của Collector:
  - Trạng thái Windows Service `PrismaFlexCollectorService` (PID, bộ nhớ, uptime).
  - Trạng thái cổng 3001 (User) và 3002 (Service).
  - Thử ping 11 máy lọc PrismaFlex (`192.168.5.21` đến `192.168.5.31`).
  - Kích thước SQLite DB & file WAL.
  - Số lượng file đọng trong outbox ready.
- **Cách chạy**:
  ```powershell
  .\Inspect-CollectorService.ps1 -OutputFile "..\reports\2026-10-xx_collector-audit-target.md"
  ```

## 2. `Verify-CollectorHandoff.ps1`
- **Mục đích**: Theo dõi hàng đợi outbox trong 15s để đảm bảo file JSON mới sinh được Mirth Connect OIE (`PF_01_RAW_DECODE`) nhận và xử lý ngay lập tức.
- **Cách chạy**:
  ```powershell
  .\Verify-CollectorHandoff.ps1
  ```
