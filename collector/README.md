# PrismaFlex Collector — Agent Bridge Workspace

Chào mừng đến với **Collector Workspace** trong repository `PrismaFlex-Agent-Bridge`.

Đây là không gian làm việc và kênh giao tiếp chuyên biệt (dedicated bidirectional channel) giữa:
- **Dev Agent** (tại máy phát triển / Development Station): Quản trị kiến trúc, tối ưu mã nguồn, tạo bản vá, phân tích log, và đưa ra chỉ thị kỹ thuật.
- **Target Agent** (tại máy trạm lâm sàng ICU-B Bệnh viện Chợ Rẫy / Host IP: `192.168.5.1`): Quản trị hiện trường, thực thi kiểm tra, thu thập số liệu vận hành, trích xuất metrics và áp dụng các tinh chỉnh cấu hình/bản vá.

---

## 1. Vai trò của Phân hệ PrismaFlex Collector

PrismaFlex Collector (phiên bản v2, dịch vụ Windows Service `PrismaFlexCollectorService`) là tầng thu nhận dữ liệu thô (raw-stream ingestion) tối quan trọng của hệ thống:
1. **Thu nhận dòng dữ liệu kép (Dual-port Ingestion)**:
   - Cổng người dùng (User Port `3001` TCP): Dòng dữ liệu hiển thị lâm sàng cơ bản.
   - Cổng kỹ thuật (Service Port `3002` TCP): Dòng dữ liệu chẩn đoán kỹ thuật sâu, ưu tiên cao hơn.
2. **Lưu trữ bền vững SQLite WAL**: Lưu byte-for-byte mọi gói tin nhận được từ các máy lọc PrismaFlex kết nối qua switch y tế LAN `192.168.5.0/24` (bộ chuyển đổi Moxa / Ethernet).
3. **Bộ chọn luồng tất định (Deterministic Stream Selector)**: Lựa chọn luồng dữ liệu tối ưu theo mốc thời gian, xử lý failover tự động nếu một cổng bị gián đoạn mà không làm mất tính liên tục.
4. **Phát hành tệp JSON Outbox**: Xuất các snapshot gói tin định dạng JSON nguyên tử vào `<outbound root>\ready` để kênh Mirth Connect OIE (`PF_01_RAW_DECODE`) xử lý đưa vào cơ sở dữ liệu lâm sàng.

---

## 2. Cấu trúc Thư mục Workspace

```text
collector/
├── README.md                              # Tài liệu định hướng và quy chuẩn giao tiếp (file này)
├── STATUS.md                              # Bảng theo dõi trạng thái vận hành, socket, thiết bị và lịch sử đồng bộ
├── requests/                              # Chiều Dev Agent -> Target Agent: Chỉ thị, yêu cầu tinh chỉnh, kịch bản test
│   ├── README.md
│   └── 2026-10-24_collector-directives-and-handshake.md
├── reports/                               # Chiều Target Agent -> Dev Agent: Báo cáo audit, đo đạc socket, metrics hàng đợi
│   ├── README.md
│   └── 2026-10-24_collector-baseline-assessment.md
├── configs/                               # Cấu hình chuẩn, template tham chiếu và hướng dẫn tinh chỉnh tham số
│   ├── README.md
│   ├── collector_service.template.json    # Template cấu hình chuẩn v2 đầy đủ 11 thiết bị
│   ├── devices.map.json                   # Bảng ánh xạ IP, port, ID và vị trí giường bệnh
│   └── tuning_parameters.md               # Sổ tay giải thích và hướng dẫn tinh chỉnh tham số mạng/runtime
├── scripts/                               # Công cụ hỗ trợ kiểm tra và vận hành an toàn cho Target Agent
│   ├── README.md
│   ├── Inspect-CollectorService.ps1       # Script PowerShell kiểm tra toàn diện Collector hiện trường
│   └── Verify-CollectorHandoff.ps1        # Script kiểm tra hàng đợi outbox ready và chuỗi chuyển tiếp OIE
└── patches/                               # Nơi lưu trữ các bản vá khẩn cấp, hotfix script không qua full release
    └── README.md
```

---

## 3. Quy trình Giao tiếp Agent-to-Agent (A2A Protocol)

### Bước 1: Phát hành Chỉ thị / Yêu cầu (`collector/requests/`)
- Dev Agent tạo file dạng `YYYY-MM-DD_<tieu-de>.md` trong `collector/requests/`.
- Nội dung bao gồm: Mục tiêu, phạm vi thay đổi (cấu hình, bản vá, kiểm tra chẩn đoán), điều kiện tiên quyết và tiêu chí nghiệm thu (Acceptance Criteria).
- Commit và `git push` lên nhánh `main`.

### Bước 2: Tiếp nhận & Thực thi trên Máy đích
- Target Agent thực hiện `git pull --ff-only`.
- Đọc nội dung request, kiểm tra các điều kiện an toàn lâm sàng.
- Sử dụng các script trong `collector/scripts/` hoặc áp dụng cấu hình/bản vá theo chỉ dẫn.
- **Nguyên tắc an toàn:** Tuyệt đối không can thiệp hoặc khởi động lại dịch vụ nếu có ca lọc đang `RECORDING / IN_PROGRESS` trừ khi có kế hoạch và phương án bảo vệ hàng đợi.

### Bước 3: Phản hồi Báo cáo (`collector/reports/`)
- Target Agent tổng hợp kết quả thành file `YYYY-MM-DD_<tieu-de>-target.md` trong `collector/reports/`.
- Đính kèm output kiểm tra thực tế (PID, socket status, ping latency, SQLite WAL size, queue backlog).
- **Khử định danh bắt buộc (De-identification):** Tuyệt đối không đưa Patient ID thật, thông tin bảo mật bệnh nhân, license key phần cứng, mật khẩu lên GitHub.
- Cập nhật file `collector/STATUS.md` và `git push` phản hồi về Dev Agent.

---

## 4. Nguyên tắc An toàn Y tế & Kỹ thuật Bắt buộc (Clinical Safety Protocols)

1. **Bảo toàn dữ liệu ca điều trị (Treatment Continuity)**:
   - Dữ liệu thô phải được ghi liên tục, không được phép làm đứt quãng mốc thời gian lâm sàng hoặc làm mất ID ca điều trị (`treatment_id`).
2. **Đơn quyền sở hữu tài nguyên (Single Instance Mutex)**:
   - Chỉ duy nhất một tiến trình `PrismaFlexCollectorService.exe` được phép chiếm dụng cổng socket 3001/3002 và ghi file SQLite.
   - Không chạy song song Collector thử nghiệm cạnh tranh với dịch vụ production.
3. **Bảo vệ hàng đợi & SQLite WAL**:
   - Không xóa các file database `*.db`, `*.db-wal`, `*.db-shm` trong runtime directory (`C:\ProgramData\PrismaFlex\Collector`).
   - Nếu khởi động lại dịch vụ, phải đảm bảo các gói tin còn đọng trong hàng đợi SQLite được xả thành công sang OIE sau khi dịch vụ lên lại.
4. **Cô lập mạng Y tế (Isolated Medical LAN)**:
   - Card mạng Ethernet `192.168.5.1/24` kết nối switch máy lọc là mạng cô lập. Không cấu hình Default Gateway trên card này để bảo đảm an ninh mạng y tế theo tiêu chuẩn bệnh viện. Mọi lưu lượng kết nối Internet/GitHub đi qua card Wi-Fi (`192.168.68.62`).
