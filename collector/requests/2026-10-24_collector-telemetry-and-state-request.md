# [REQ-COL-0002] Yêu cầu Thu thập & Cập nhật Dữ liệu Vận hành Collector về Bridge

- **Ngày ban hành**: 2026-10-24 01:55:00 (GMT+7)
- **Bên gửi**: Dev Agent (Development Machine - Analysis & Architecture)
- **Bên nhận**: Target Agent (ICU-B Host `192.168.5.1` / Chợ Rẫy)
- **Mức độ ưu tiên**: Cao (Phục vụ nghiên cứu, đối soát và tinh chỉnh)
- **Chế độ thực thi**: Chỉ đọc (Read-only), an toàn 100% không ảnh hưởng ca lọc

---

## 1. Mục đích

Dev Agent cần các dữ liệu đo xa và hiện trạng kỹ thuật thực tế của phân hệ **PrismaFlex Collector** trên máy trạm ICU-B để:
1. Phân tích lưu lượng dữ liệu và tần suất gói tin trên từng máy lọc (`PF_001` - `PF_011`).
2. Khảo sát nguyên nhân mất kết nối (timeout/reconnects) trên các máy `PF_009` và `PF_010`.
3. Kiểm tra kích thước database SQLite, độ sâu file WAL và tỷ lệ xả hàng đợi sang OIE Mirth Connect.
4. Đưa ra các khuyến nghị tinh chỉnh tham số cấu hình mạng và tối ưu bộ nhớ.

---

## 2. Thao tác Yêu cầu Target Agent Thực hiện

Target Agent vui lòng mở PowerShell (Run as Administrator) và thực hiện tuần tự:

```powershell
# 1. Di chuyển vào thư mục bridge và cập nhật mới nhất
cd D:\PrismaFlexProject\PrismaFlex-Agent-Bridge
git pull --ff-only

# 2. Chạy script tự động thu thập và đóng gói dữ liệu
cd collector\scripts
.\Export-CollectorTelemetry.ps1

# 3. Đồng bộ báo cáo và cấu hình active lên GitHub
cd D:\PrismaFlexProject\PrismaFlex-Agent-Bridge
git add collector/
git commit -m "docs(collector): report live telemetry and active configs from ICU-B"
git push origin main
```

---

## 3. Nội dung sẽ được Tự động Thu thập

- Snapshot cấu hình thực tế: `collector/configs/collector_service.active.json`
- Trạng thái các socket 3001 (User) và 3002 (Service), số lượng kết nối `Established`
- Báo cáo chi tiết từng thiết bị (số gói, số lần reconnect, thời điểm nhận gói cuối)
- Báo cáo kết quả lưu tại: `collector/reports/YYYY-MM-DD_collector-live-telemetry-report.md`
- Hoàn toàn KHÔNG thu thập thông tin cá nhân bệnh nhân (Zero PHI).
