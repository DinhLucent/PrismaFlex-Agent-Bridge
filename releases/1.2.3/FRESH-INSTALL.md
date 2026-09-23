# Chỉ dùng khi cần cài mới WebPlatform protocol 2

Máy đang chạy 1.2.1 bình thường đi theo START-HERE, không cài mới. Quy trình này dành cho máy mới hoặc phương án chuyển khỏi demo/source đã xác định rõ. Không tự xóa bản cũ/DB để biến thành cài mới.

## Điều kiện

- Windows x64, quyền Administrator; bộ 1.2.3 đầy đủ đã kiểm tra SHA/chữ ký.
- PostgreSQL 16 đã cài, database riêng **rỗng**, tài khoản có quyền tạo schema/bảng và backup. PostgreSQL không nằm trong ZIP.
- Không có services `prismaflex-api`, `prismaflex-web`, `prismaflex-analyzer` thuộc một installation khác. Tên services cố định nên không cài song song hai installation trên cùng Windows. Chuyển khỏi source/demo phải kiểm kê và dừng cơ chế tự khởi động cũ trong cửa sổ bảo trì, giữ phương án quay lại.
- Thư mục install mới, cổng API/Web/Analyzer không bị chiếm. Không trùng các cổng Collector 3001/3002.
- Owner có thể cấp license đúng fingerprint của máy này. Agent máy đích không có private key để tự cấp; không lấy license máy khác hoặc khóa test để vượt bước này.

## 1. Xác lập niềm tin và tạo cấu hình

Dùng `api\prismaflex.exe` của package làm verifier ban đầu **sau khi** đối chiếu SHA của EXE với `PACKAGE-INFO.json` lấy từ kênh bàn giao tin cậy; sau đó chạy `verify-release --directory $package --deployment`. Máy đã cài thì dùng verifier cũ, không đi bước này.

Ví dụ PowerShell Administrator (điền đường dẫn thật, không đặt file config vào repo):

```powershell
$installRoot = 'C:\PrismaFlex'
$package = 'D:\PrismaFlexMedia\1.2.3\expanded\PrismaFlex-1.2.3-windows-x64\release'
$info = Get-Content -LiteralPath (Join-Path (Split-Path $package) 'PACKAGE-INFO.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$verifier = Join-Path $package 'api\prismaflex.exe'
if ((Get-FileHash -LiteralPath $verifier).Hash -ne $info.verifier_sha256) { throw 'Verifier hash mismatch' }
& $verifier verify-release --directory $package --deployment
if ($LASTEXITCODE -ne 0) { throw 'Invalid release' }
$pgBin = 'C:\Program Files\PostgreSQL\16\bin'
$configPath = 'D:\PrismaFlexMedia\runtime-private.json'
$dbHost = '127.0.0.1'; $dbPort = 5432; $dbName = 'prismaflex_new'
$dbCredential = Get-Credential -Message 'Credentials for the dedicated empty database'
$encodedUser = [uri]::EscapeDataString($dbCredential.UserName)
$encodedPassword = [uri]::EscapeDataString($dbCredential.GetNetworkCredential().Password)
$dbUrl = 'postgresql+psycopg2://{0}:{1}@{2}:{3}/{4}' -f $encodedUser,$encodedPassword,$dbHost,$dbPort,([uri]::EscapeDataString($dbName))
$meta = Get-Content -LiteralPath (Join-Path $package 'release.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$random = New-Object byte[] 32
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($random) } finally { $rng.Dispose() }
$config = [ordered]@{
  POSTGRES_URL=$dbUrl; SITE_PROFILE_HASH=$meta.site_profile_hash
  CORS_ORIGINS=@(); NETWORK_SCHEMA=2; HOST='127.0.0.1'; PORT=8000
  WEB_PORT=3000; PUBLIC_HOST=''; AUTH_COOKIE_SECURE=$false; AUTH_COOKIE_SAMESITE='lax'
  ENABLE_TREATMENT_ANALYZER=$true; ANALYZER_PORT=15555
  TREATMENT_ANALYZER_SERVICE_KEY=[Convert]::ToBase64String($random)
}
if (Test-Path -LiteralPath $configPath) { throw 'Choose a new private config path' }
[IO.File]::WriteAllText($configPath,($config | ConvertTo-Json -Depth 5),[Text.UTF8Encoding]::new($false))
Remove-Variable dbCredential,encodedPassword,dbUrl,config,random
```

Protocol 2 dùng Web cùng origin để proxy API/WS, không lấy `web_origin/api_origin` từ site schema 1. LAN truy cập Web port đã chọn; API và Analyzer giữ loopback. Chỉ mở firewall Web cho mạng nội bộ cần dùng theo chính sách site. TLS/reverse proxy cần cấu hình/kiểm tra riêng; không tự bật Secure cookie trên HTTP.

File config chứa mật khẩu: giữ ngoài GitHub và hạn chế quyền truy cập. Bản sao config do installer quản lý trong `shared` có ACL riêng.

## 2. Stage và kích hoạt

```powershell
$installer = Join-Path $package 'deployment\install\Install-Release.ps1'
$installArgs = @{
  PackageDir=$package; InstallRoot=$installRoot; TrustedVerifier=$verifier
  TrustedVerifierSha256=$info.verifier_sha256; Config=$configPath; PgBin=$pgBin
}
& $installer @installArgs
```

Exit **20** khi chưa có license là stage thành công, chưa chạy dịch vụ. Exit khác 0/20 cần điều tra trước khi tiếp tục.

```powershell
$installedExe = Join-Path $installRoot 'releases\1.2.3\api\prismaflex.exe'
& $installedExe --install-root $installRoot request --out 'D:\PrismaFlexMedia\activation-request.json'
if ($LASTEXITCODE -ne 0) { throw 'Activation request failed' }
```

Gửi request qua kênh riêng cho owner, nhận license đã ký rồi:

```powershell
& $installedExe --install-root $installRoot activate --license 'D:\PrismaFlexMedia\activation-license.json'
if ($LASTEXITCODE -ne 0) { throw 'Activation failed' }
& $installer @installArgs
if ($LASTEXITCODE -ne 0) { throw 'Installation incomplete; preserve state and logs' }
```

Installer yêu cầu DB rỗng, chạy migration, đăng ký services và kiểm tra readiness. Nếu phase MIGRATING dở dang, không tự drop DB/reset state. Không chạy lại `init-ca` trên máy đích.

## 3. Tạo admin đầu tiên và nghiệm thu

Chỉ trên DB cài mới, không bootstrap lại khi update:

```powershell
$adminCredential = Get-Credential -Message 'Initial PrismaFlex administrator'
$adminCredential.GetNetworkCredential().Password | & $installedExe --install-root $installRoot bootstrap-admin `
  --username $adminCredential.UserName --display-name 'Site Administrator' --password-stdin
if ($LASTEXITCODE -ne 0) { throw 'Admin bootstrap failed' }
Remove-Variable adminCredential
```

Xác nhận `install-state.phase=READY`, services Running, `ready`, login và trang monitor từ máy trạm. Cài mới chưa có `update.json` là bình thường: không dùng `Inspect-Target -Phase After` (script đó kiểm tra cập nhật có journal HEALTHY). Tiếp tục checklist LIVE/chart/journal trong START-HERE. Chỉ cấu hình OIE gửi vào đúng endpoint sau khi API đã sẵn sàng; Collector/OIE triển khai riêng. Giữ nguyên `delivery_id` và thời gian canonical từ decoder.
