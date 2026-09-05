# ============================================================
# J.A.R.V.I.S - Script xuất bản (Phần 5)
#
# Tạo bản phát hành: TỆP ĐƠN (.exe) + kèm appsettings.json,
# chạy được ngay trên Windows 10/11 KHÔNG cần cài .NET runtime.
#
# Cách dùng:
#   powershell -ExecutionPolicy Bypass -File .\publish.ps1
#
# Kết quả: .\publish\JarvisAssistant.exe (+ appsettings.json)
# ============================================================

$ErrorActionPreference = 'Stop'

# --- 1. Thông số xuất bản -------------------------------------
$project  = Join-Path $PSScriptRoot 'JarvisAssistant\JarvisAssistant.csproj'
$output   = Join-Path $PSScriptRoot 'publish'
$runtime  = 'win-x64'          # Windows 64-bit (đa số máy hiện nay)
$config   = 'Release'

Write-Host "==> Xuat ban J.A.R.V.I.S ($config, $runtime, file don)..." -ForegroundColor Cyan

# --- 2. Xuất bản (single-file self-contained) -----------------
#  - PublishSingleFile          : gom toàn bộ DLL vào 1 .exe
#  - SelfContained              : kèm sẵn .NET runtime -> không cần cài .NET
#  - IncludeNativeLibrariesForSelfExtract: tách DLL gốc ra khỏi bundle nếu
#    có lỗi (đảm bảo tương thích tối đa với Win 10/11)
#  - DebugType=None             : bỏ PDB cho gọn
dotnet publish $project `
    -c $config `
    -r $runtime `
    --self-contained true `
    -o $output `
    /p:PublishSingleFile=true `
    /p:IncludeNativeLibrariesForSelfExtract=true `
    /p:DebugType=None `
    /p:DebugSymbols=false `
    /p:PublishReadyToRun=true

if ($LASTEXITCODE -ne 0) {
    Write-Host "XUAT BAN THAT BAI (exit code $LASTEXITCODE)." -ForegroundColor Red
    exit $LASTEXITCODE
}

# --- 3. Kiểm tra kết quả --------------------------------------
$exe    = Join-Path $output 'JarvisAssistant.exe'
$cfg    = Join-Path $output 'appsettings.json'

# Đảm bảo appsettings.json nằm cạnh exe (dotnet publish thỉnh thoảng
# không copy file None/CopyToOutputDirectory trong lần publish kế tiếp).
if (Test-Path (Join-Path $PSScriptRoot 'JarvisAssistant\appsettings.json')) {
    Copy-Item -Path (Join-Path $PSScriptRoot 'JarvisAssistant\appsettings.json') -Destination $cfg -Force
}

if (-not (Test-Path $exe)) {
    Write-Host "KHONG TIM THAY $exe - xuat ban co van de." -ForegroundColor Red
    exit 1
}

$size = [Math]::Round((Get-Item $exe).Length / 1MB, 1)
Write-Host "OK: $exe  ($size MB, single-file self-contained)" -ForegroundColor Green

if (-not (Test-Path $cfg)) {
    Write-Host "CANH BAO: thieu appsettings.json ben canh exe - cau hinh se dung mac dinh." -ForegroundColor Yellow
} else {
    Write-Host "OK: $cfg" -ForegroundColor Green
}

Write-Host ""
Write-Host "HOAN TAT. Chay thu:" -ForegroundColor Cyan
Write-Host "   $exe"
Write-Host "(app chay an tren System Tray; Lua y: kiem tra phan mem tam soat truoc khi dung)"