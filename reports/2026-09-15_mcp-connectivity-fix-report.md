# Báo cáo Xử lý Lỗi Kết nối MCP Servers (CodeGraph & CUA-Driver)

- **Ngày thực hiện**: 2026-09-15
- **Thiết bị / Môi trường**: DSH Web Platform (`http://127.0.0.1:3080`)
- **Trạng thái**: **HOÀN THÀNH - TOÀN BỘ 5 MCP SERVERS ĐÃ KẾT NỐI (HEALTHY)**

---

## 1. Hiện trạng trước khi xử lý

Kiểm tra API `http://127.0.0.1:3080/api/dsh-mcp/servers`:
- **Tổng số server**: 5
- **Đã kết nối**: 3 (`agentation`, `stitch`, `chrome-devtools`)
- **Bị lỗi (Failed)**: 2
  1. `codegraph`: Lỗi `spawn codegraph ENOENT` (10 reconnect attempts). Nguyên nhân do lệnh cấu hình là `codegraph serve --mcp`, nhưng gói nhị phân / CLI `codegraph` không tồn tại trong hệ thống.
  2. `cua-driver`: Lỗi `spawn C:\Users\ADMIN\AppData\Local\Programs\Cua\cua-driver\bin\cua-driver.exe ENOENT`. Nguyên nhân do đường dẫn trỏ tới user `ADMIN`, trong khi user hiện tại của Windows là `Administrator` và file thực thi chưa được cài đặt.

---

## 2. Các bước xử lý triệt để

### A. Đối với CodeGraph MCP (`codegraph`)
1. Xác định package chính thức: `@astudioplus/codegraph-mcp` (chứa đầy đủ 42 công cụ phân tích AST, call graph, code intelligence, symbol search, memory, architecture doc).
2. Cài đặt toàn cục `@astudioplus/codegraph-mcp` via npm.
3. Cập nhật cấu hình server trong `dsh-mcp-manager` qua API PATCH:
   - `command`: `npx`
   - `args`: `["-y", "@astudioplus/codegraph-mcp"]`
   - Đồng bộ lưu trữ tại `C:\Users\Administrator\.dsh\dsh-mcp.json`.

### B. Đối với CUA Driver MCP (`cua-driver`)
1. Tải bản phân phối nhị phân chính thức cho Windows x86_64 từ GitHub release `trycua/cua` (v0.28.1: `cua-driver-rs-0.28.1-windows-x86_64-binary.zip`).
2. Giải nén vào thư mục chuẩn: `C:\Users\Administrator\AppData\Local\Programs\Cua\cua-driver\bin\`.
3. Tạo Directory Junction `C:\Users\ADMIN` trỏ về `C:\Users\Administrator` để tương thích triệt để với bất kỳ tool / script nào hardcode đường dẫn cũ.
4. Cập nhật cấu hình server trong `dsh-mcp-manager` qua API PATCH:
   - `command`: `C:\Users\Administrator\AppData\Local\Programs\Cua\cua-driver\bin\cua-driver.exe`
   - `args`: `["mcp"]`

---

## 3. Kết quả nghiệm thu hệ thống

Kiểm tra API `/api/dsh-mcp/health` và `/api/dsh-mcp/servers`:
- **Trạng thái tổng thể**: `ok: true`
- **Số server kết nối**: `5 / 5` (`failed: 0`, `stopped: 0`)
- **Tổng số công cụ MCP khả dụng**: **153 tools**

| Tên MCP Server | Trạng thái | Số lượng Tools | Ghi chú tính năng |
|---|---|---|---|
| `codegraph` | `connected` | **42 tools** | AST, call graph, blast radius, symbol search, memory context |
| `cua-driver` | `connected` | **57 tools** | GUI automation, UIA accessibility tree, mouse/keyboard |
| `chrome-devtools` | `connected` | **29 tools** | Browser automation, DOM snapshot, console/network inspection |
| `stitch` | `connected` | **16 tools** | Google Stitch AI UI design system & screen generation |
| `agentation` | `connected` | **9 tools** | Visual feedback & web page annotation |
