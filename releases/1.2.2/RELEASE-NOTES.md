# PrismaFlex 1.2.2 — bản bàn giao nghiệm thu

Bản Windows x64 đã ký, sửa thời gian hiển thị, chart live và Treatment Journal. Verifier 1.2.1 xác minh gói mới thành công. Không đóng gói Collector/OIE/PostgreSQL, license kích hoạt hoặc dữ liệu bệnh nhân.

Tải `PrismaFlex-1.2.2-windows-x64.zip` và file `.sha256`, đọc [START-HERE](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/blob/main/releases/1.2.2/START-HERE.md), [hướng dẫn update](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/blob/main/releases/1.2.2/UPDATE.md) và [review](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/blob/main/releases/1.2.2/REVIEW.md).

Đây là prerelease để agent máy đích nghiệm thu. Test source, state machine updater và chữ ký đã pass; chưa thử cập nhật Windows Service tại máy đích. Tải lớn/soak dài chưa được kiểm chứng, burst trước đó vượt SLO. Giai đoạn đầu không bắt buộc nối liền treatment qua update, nhưng phải backup và không tự duyệt/hoàn tất ca.

Source: `886cc46afdfe842acc9ee6abe719179ac8bbc592`. Database revision: `d4b2a8f91c30`. Management protocol: 2.
