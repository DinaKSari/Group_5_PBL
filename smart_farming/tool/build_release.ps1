<#
    Build APK rilis LettuGrow yang tanda tangannya benar.

    Versi APK diambil dari pubspec.yaml lalu dioper ke aplikasi lewat
    --dart-define=APP_VERSION, supaya pembanding Remote Config
    (minimum_supported_version) memakai angka yang sama dengan yang dibaca
    manusia di pubspec - tidak ada angka yang harus diingat manual.

    Base URL TIDAK di-pin di sini secara default: APK rilis memakai Remote
    Config (Console -> api_base_url) dan jatuh ke default rilis di
    lib/config/api_config.dart kalau Remote Config belum diset. Pakai
    -ApiBaseUrl hanya kalau kalian sengaja mengunci satu host (mis. demo
    tanpa akses Console); nilai itu menang atas Remote Config.

    Contoh:
      powershell -ExecutionPolicy Bypass -File tool\build_release.ps1
      powershell -ExecutionPolicy Bypass -File tool\build_release.ps1 -Clean
      powershell -ExecutionPolicy Bypass -File tool\build_release.ps1 -ApiBaseUrl https://craftily-handcraft-outboard.ngrok-free.dev/api
#>
param(
    [string]$ApiBaseUrl = '',
    [switch]$Clean,
    [switch]$AllowDebugSigning
)

$ErrorActionPreference = 'Stop'
$smartFarmingDir = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $smartFarmingDir 'pubspec.yaml'
$keyPropsPath = Join-Path $smartFarmingDir 'android/key.properties'
$apkPath = Join-Path $smartFarmingDir 'build/app/outputs/flutter-apk/app-release.apk'

function Write-Step([string]$Message) { Write-Host "== $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK]  $Message" -ForegroundColor Green }
function Stop-WithError([string]$Message) {
    Write-Host "[X]   $Message" -ForegroundColor Red
    exit 1
}

Write-Step 'Versi dari pubspec.yaml'
if (-not (Test-Path $pubspecPath)) { Stop-WithError "Tidak ada $pubspecPath." }
$versionLine = (Get-Content $pubspecPath | Where-Object { $_ -match '^version:\s*(\S+)' } | Select-Object -First 1)
if (-not $versionLine) { Stop-WithError 'Baris `version:` tidak ditemukan di pubspec.yaml.' }
$appVersion = ($versionLine -replace '^version:\s*', '') -replace '\+.*$', ''
Write-Ok "APP_VERSION = $appVersion (dari $versionLine)"

Write-Step 'Keystore rilis'
if (-not (Test-Path $keyPropsPath)) {
    if (-not $AllowDebugSigning) {
        Stop-WithError @'
android/key.properties belum ada. Tanpa itu APK rilis tetap bertanda tangan DEBUG,
dan tidak ada cara untuk menggantinya nanti di HP user yang sudah memasang.
Buat dulu: powershell -ExecutionPolicy Bypass -File tool\make_keystore.ps1
(Kalau memang hanya ingin mencoba build: tambahkan -AllowDebugSigning.)
'@
    }
    Write-Warning 'key.properties tidak ada -> APK akan bertanda tangan debug. Jangan diedarkan.'
} else {
    Write-Ok 'key.properties ditemukan.'
}

if ($Clean) {
    Write-Step 'flutter clean'
    Push-Location $smartFarmingDir
    try {
        flutter clean | Out-Host
        if ($LASTEXITCODE -ne 0) { Stop-WithError "flutter clean gagal (exit $LASTEXITCODE)." }
    } finally { Pop-Location }
}

Write-Step 'flutter build apk --release'
$buildArgs = @('build', 'apk', '--release', "--dart-define=APP_VERSION=$appVersion")
if ($ApiBaseUrl) { $buildArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl" }

Push-Location $smartFarmingDir
try {
    flutter @buildArgs | Out-Host
    $buildExit = $LASTEXITCODE
} finally { Pop-Location }
if ($buildExit -ne 0) { Stop-WithError "flutter build gagal (exit $buildExit)." }

if (-not (Test-Path $apkPath)) { Stop-WithError "Build selesai tapi $apkPath tidak ada." }
$item = Get-Item $apkPath
Write-Ok "APK: $apkPath  ($([math]::Round($item.Length / 1MB, 1)) MB, $($item.LastWriteTime))"

Write-Step 'Verifikasi sertifikat'
$keyTool = $null
if ($env:JAVA_HOME) { $keyTool = Join-Path $env:JAVA_HOME 'bin/keytool.exe' }
if (-not $keyTool -or -not (Test-Path $keyTool)) { $keyTool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' }
if (Test-Path $keyTool) {
    $cert = & $keyTool '-printcert' '-jarfile' $apkPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "keytool tidak bisa membaca tanda tangan APK (mungkin hanya signing v2). Cek manual: $apkPath"
    } elseif ($cert -match 'CN=Android Debug') {
        Write-Warning 'APK ini bertanda tangan DEBUG. Jangan diedarkan ke user.'
    } else {
        ($cert | Select-Object -First 6) | Out-Host
        Write-Ok 'Sertifikat rilis terbaca (bukan debug).'
    }
} else {
    Write-Warning 'keytool tidak ditemukan; verifikasi sertifikat dilakukan manual.'
}

Write-Host ''
Write-Host 'Langkah berikutnya (RUNBOOK R7): pasang ke HP, cek login/prediksi/catat parameter.' -ForegroundColor Cyan
Write-Host "File siap kirim: $apkPath"
