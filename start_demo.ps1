[CmdletBinding()]
param(
    [string]$Device = ''
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$backendDir = Join-Path $root 'smart_farming\backend'
$flutterDir = Join-Path $root 'smart_farming'
$mlDir = Join-Path $root 'ML\api'
$backendEnv = Join-Path $backendDir '.env'

function Stop-DemoSetup([string]$Message) {
    Write-Host "`n[PERLU DIBENAHI] $Message" -ForegroundColor Red
    exit 1
}

function Test-ListeningPort([int]$Port) {
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Read-EnvValue([string]$Name) {
    $line = Get-Content -LiteralPath $backendEnv | Where-Object { $_ -match "^\s*$([regex]::Escape($Name))\s*=" } | Select-Object -First 1
    if (-not $line) { return '' }
    $value = ($line -split '=', 2)[1].Trim()
    if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
        $value = $value.Substring(1, $value.Length - 2)
    }
    return $value
}

Write-Host '========================================' -ForegroundColor Green
Write-Host ' Demo LettuGrow - Selada Hidroponik' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green

# Pastikan persiapan sekali-seumur hidup sudah ada.
foreach ($path in @(
    $backendEnv,
    (Join-Path $backendDir 'vendor\autoload.php'),
    (Join-Path $mlDir '.venv\Scripts\python.exe'),
    (Join-Path $mlDir 'artifacts\model.joblib'),
    (Join-Path $mlDir 'artifacts\classifier.joblib'),
    (Join-Path $mlDir 'artifacts\cluster.joblib')
)) {
    if (-not (Test-Path -LiteralPath $path)) {
        Stop-DemoSetup "File prasyarat tidak ditemukan: $path. Lihat bagian 'Persiapan sekali saja' pada panduan demo."
    }
}

$secret = Read-EnvValue 'FLASK_ML_SHARED_SECRET'
if ([string]::IsNullOrWhiteSpace($secret)) {
    Stop-DemoSetup 'FLASK_ML_SHARED_SECRET belum diisi di smart_farming\backend\.env.'
}

$firebasePath = Read-EnvValue 'FIREBASE_CREDENTIALS'
if ([string]::IsNullOrWhiteSpace($firebasePath)) {
    Stop-DemoSetup 'FIREBASE_CREDENTIALS belum diisi di smart_farming\backend\.env.'
}
if (-not [IO.Path]::IsPathRooted($firebasePath)) {
    $firebasePath = Join-Path $backendDir $firebasePath
}
if (-not (Test-Path -LiteralPath $firebasePath)) {
    Stop-DemoSetup 'File Firebase service-account tidak ditemukan. Jangan kirim file itu ke chat atau commit ke Git.'
}

# MySQL dipakai bersama proyek lain melalui Laragon; skrip ini tidak mematikan atau mengubahnya.
if (-not (Test-ListeningPort 3306)) {
    Stop-DemoSetup 'MySQL belum berjalan. Buka Laragon, klik Start All, tunggu MySQL aktif, lalu jalankan skrip ini lagi.'
}

# Versi lockfile proyek membutuhkan PHP 8.4. Jangan memakai PHP 8.3 dari Laragon.
$wingetPackages = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
$phpPackage = Get-ChildItem -Path $wingetPackages -Directory -Filter 'PHP.PHP.8.4*' -ErrorAction SilentlyContinue |
    Sort-Object FullName -Descending | Select-Object -First 1
if (-not $phpPackage) {
    Stop-DemoSetup 'PHP 8.4 tidak ditemukan. Instal PHP.PHP.8.4 lewat winget atau minta bantuan pengelola proyek.'
}
$phpExe = Join-Path $phpPackage.FullName 'php.exe'
$phpIni = Join-Path $phpPackage.FullName 'php.ini'
$caBundle = Join-Path $phpPackage.FullName 'certs\cacert.pem'
if (-not (Test-Path $caBundle) -or -not (Test-Path $phpIni)) {
    Stop-DemoSetup 'Konfigurasi PHP/CA certificate belum lengkap. Tanpa CA bundle, Laravel tidak bisa memverifikasi Firebase.'
}
$env:PATH = "$($phpPackage.FullName);$env:PATH"
$env:PHPRC = $phpPackage.FullName

# Cari Android Debug Bridge dari Android Studio SDK.
$sdkCandidates = @(
    $env:ANDROID_SDK_ROOT,
    $env:ANDROID_HOME,
    (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
) | Where-Object { $_ -and (Test-Path $_) }
$adbExe = $null
foreach ($sdk in $sdkCandidates) {
    $candidate = Join-Path $sdk 'platform-tools\adb.exe'
    if (Test-Path $candidate) { $adbExe = $candidate; break }
}
if (-not $adbExe) {
    Stop-DemoSetup 'ADB tidak ditemukan. Instal Android SDK Platform-Tools melalui Android Studio > SDK Manager.'
}
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) { Stop-DemoSetup 'Perintah Flutter tidak ditemukan di PATH.' }

if ((Test-ListeningPort 5000) -or (Test-ListeningPort 8000)) {
    Stop-DemoSetup 'Port 5000 atau 8000 sudah dipakai. Tutup jendela Flask/Laravel demo sebelumnya, lalu jalankan ulang skrip ini.'
}

$deviceSerial = $Device
if ([string]::IsNullOrWhiteSpace($deviceSerial)) {
    $connected = @(& $adbExe devices | Where-Object { $_ -match '^\S+\s+device(?:\s|$)' })
    if ($connected.Count -eq 0) {
        Stop-DemoSetup 'Emulator/perangkat Android belum terhubung. Buka Android Studio, jalankan emulator, lalu ulangi.'
    }
    $deviceSerial = ($connected[0] -split '\s+')[0]
}

# Periksa migrasi sebelum layanan dibuka.
Push-Location $backendDir
try {
    & $phpExe artisan config:clear
    if ($LASTEXITCODE -ne 0) { Stop-DemoSetup 'Laravel gagal membersihkan konfigurasi lama.' }
    & $phpExe artisan migrate --force
    if ($LASTEXITCODE -ne 0) { Stop-DemoSetup 'Migrasi database gagal. Pastikan Laragon/MySQL aktif dan database smart_farming tersedia.' }
} finally {
    Pop-Location
}

# Rahasia hanya diwariskan ke proses Flask; nilainya tidak pernah dicetak.
$env:ML_SHARED_SECRET = $secret
$env:FLASK_ML_SHARED_SECRET = $secret
$env:APP_DEBUG = 'false'

Write-Host "`n[1/3] Menyalakan Flask ML di port 5000..."
Start-Process -FilePath (Join-Path $mlDir '.venv\Scripts\python.exe') `
    -ArgumentList @('app.py') -WorkingDirectory $mlDir -PassThru | Out-Null

Write-Host '[2/3] Menyalakan Laravel di port 8000...'
Start-Process -FilePath $phpExe `
    -ArgumentList @('artisan', 'serve', '--host=127.0.0.1', '--port=8000') `
    -WorkingDirectory $backendDir -PassThru | Out-Null

Write-Host '[3/3] Menyiapkan koneksi Android lewat ADB...'
& $adbExe -s $deviceSerial reverse tcp:8000 tcp:8000
if ($LASTEXITCODE -ne 0) {
    Stop-DemoSetup 'ADB reverse gagal. Pastikan emulator menyala atau ponsel tersambung dengan USB debugging.'
}

Write-Host "`nBackend mulai di jendela terpisah. Tunggu sekitar 5 detik, lalu cek:" -ForegroundColor Yellow
Write-Host '  Flask:   http://127.0.0.1:5000/health'
Write-Host '  Laravel: http://127.0.0.1:8000/up'
Write-Host "`nJika Flask health menampilkan status=ok, aplikasi akan dibangun dan dibuka pada perangkat $deviceSerial."
Write-Host 'Tekan q pada terminal ini untuk menutup sesi Flutter; tutup juga jendela Flask dan Laravel saat selesai.'

Push-Location $flutterDir
try {
    & $flutter.Source pub get
    if ($LASTEXITCODE -ne 0) { Stop-DemoSetup 'flutter pub get gagal.' }
    & $flutter.Source run -d $deviceSerial --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
} finally {
    Pop-Location
}
