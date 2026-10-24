# Điều chỉnh quy trình ICU-B: bỏ bước Mirth

Theo yêu cầu chủ máy sau khi phát hành 1.2.4, agent **bỏ qua mọi thao tác Mirth/OIE**: không mở giao diện, sửa channel, kiểm queue, đợi retry hoặc chứng minh `delivery_id`. Mirth không phải điều kiện chặn cập nhật WebApp. Giữ nguyên service và cấu hình Mirth.

Các câu yêu cầu kiểm queue Mirth trong tài liệu **đóng sẵn bên trong ZIP đã ký** được thay thế bằng [START-HERE.md hiện hành](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/blob/main/releases/1.2.4/START-HERE.md) và [PROMPT-ICU-B-AGENT.md](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/blob/main/releases/1.2.4/PROMPT-ICU-B-AGENT.md) trên Agent Bridge sau `git pull --ff-only`. Binary, ZIP và SHA-256 bản 1.2.4 không thay đổi.

Trước update, ghi cục bộ ID/start time/mốc journal của treatment đang chạy. Sau update, xác nhận từng ca giữ ID và journal ghi tiếp khi có dữ liệu mới. Không tuyên bố mọi gói trong lúc API ngừng đã được gửi bù; đánh dấu Mirth/queue **CHƯA KIỂM TRA** và ghi khoảng trống quan sát được. Không dừng máy điều trị hoặc đổi trạng thái ca để thử.
