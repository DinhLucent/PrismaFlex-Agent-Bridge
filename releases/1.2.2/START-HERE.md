# Nhận bộ cài PrismaFlex 1.2.2

Đây là bản ứng viên để nghiệm thu tại máy đích. Đọc [review](REVIEW.md) trước khi cập nhật. Bộ cài có chữ ký phát hành; trạng thái prerelease thể hiện còn bước nghiệm thu máy đích, không phải dùng khóa test.

- [Tải bộ cài từ GitHub Releases](https://github.com/DinhLucent/PrismaFlex-Agent-Bridge/releases/tag/v1.2.2-pilot)
- [Hướng dẫn cập nhật và nghiệm thu](UPDATE.md)
- [Yêu cầu cho agent máy đích](../../requests/2026-09-23-update-1.2.2.md)

Git không chứa trực tiếp ZIP. Trên máy build, ZIP và bản giải nén ở `PrismaFlex-Agent-Bridge/installers/1.2.2/`. Máy nhận có thể tải bằng GitHub CLI:

```powershell
gh release download v1.2.2-pilot --repo DinhLucent/PrismaFlex-Agent-Bridge `
    --pattern '*.zip' --pattern '*.zip.sha256' --dir installers/1.2.2
if ($LASTEXITCODE -ne 0) { throw 'Download failed' }
$zip = Join-Path $PWD 'installers\1.2.2\PrismaFlex-1.2.2-windows-x64.zip'
$expected = ((Get-Content -LiteralPath "$zip.sha256" -Raw -Encoding UTF8).Trim() -split '\s+')[0]
if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $expected) {
    throw 'ZIP checksum mismatch'
}
Expand-Archive -LiteralPath $zip -DestinationPath (Join-Path $PWD 'installers\1.2.2\expanded')
```

SHA cùng kênh tải phát hiện hỏng tệp; verifier bản đang cài xác minh chữ ký gói trước khi cập nhật. `PackageDir` là thư mục `release` bên trong bản giải nén. Không sử dụng installer của Collector hoặc source GitHub auto-generated ZIP.

Giai đoạn đầu không bắt buộc nối liền ca đang chạy qua update. Phải giữ backup, ứng dụng tiếp tục nhận dữ liệu và không tự hoàn tất/duyệt ca lâm sàng.
