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
# keytool -printcert -jarfile HANYA membaca signature v1 (JAR). Flutter menandatangani
# APK dengan scheme v2/v3 tanpa v1, jadi keytool membalas "Not a signed jar file" dengan
# exit 0 - kalau itu dianggap lulus, skrip ini mengklaim sukses tanpa bukti apa pun.
# Satu-satunya alat yang benar adalah apksigner dari build-tools.
function Find-ApkSigner {
    $roots = @()
    if ($env:ANDROID_HOME) { $roots += $env:ANDROID_HOME }
    if ($env:ANDROID_SDK_ROOT) { $roots += $env:ANDROID_SDK_ROOT }
    $roots += (Join-Path $env:LOCALAPPDATA 'Android\Sdk')
    foreach ($root in $roots) {
        $bt = Join-Path $root 'build-tools'
        if (-not (Test-Path $bt)) { continue }
        $found = Get-ChildItem -Path $bt -Filter 'apksigner.bat' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if ($found) { return $found.FullName }
    }
    return $null
}

$apkSigner = Find-ApkSigner
if (-not $apkSigner) {
    Write-Warning @'
apksigner.bat tidak ditemukan di Android SDK. build-release TETAP berhasil, tapi tanda
tangan APK BELUM terbukti. Cek manual (ganti path sesuai build-tools kalian):
  & "<sdk>\build-tools\36.0.0\apksigner.bat" verify --verbose --print-certs "<apk>"
Lulus kalau: "Verifies" + "Signer #1 certificate DN: CN=LettuGrow".
'@
} else {
    $cert = & $apkSigner 'verify' '--verbose' '--print-certs' $apkPath 2>&1
    $certText = ($cert | Out-String)
    if ($LASTEXITCODE -ne 0) {
        Stop-WithError "apksigner menolak APK ini (exit $LASTEXITCODE). APK tidak layak edar.`n$certText"
    } elseif ($certText -match 'CN=Android Debug') {
        Write-Warning 'APK ini bertanda tangan DEBUG. Jangan diedarkan ke user - key.properties tidak terbaca Gradle.'
    } elseif ($certText -notmatch 'Signer #1 certificate DN:') {
        Stop-WithError 'apksigner bilang valid tapi tidak menampilkan signer - periksa ulang APK-nya.'
    } else {
        $dn = ($cert | Where-Object { $_ -match 'Signer #1 certificate DN:' } | Select-Object -First 1)
        $sha = ($cert | Where-Object { $_ -match 'Signer #1 certificate SHA-256 digest:' } | Select-Object -First 1)
        ($dn + '').Trim() | Out-Host
        ($sha + '').Trim() | Out-Host
        $v2 = ($certText -match 'Verified using v2 scheme \(APK Signature Scheme v2\): true')
        Write-Host "  scheme v2: $v2"
        if ($dn -match 'CN=LettuGrow') {
            Write-Ok 'APK bertanda tangan sertifikat release kelompok (CN=LettuGrow).'
            Write-Host "  SHA-256 di atas HARUS sama dengan fingerprint keystore - cocokkan dengan catatan R5." -ForegroundColor DarkGray
        } else {
            Write-Warning "DN signer bukan CN=LettuGrow ('$($dn.Trim())'). APK ini mungkin memakai keystore lain."
        }
    }
}

Write-Host ''
Write-Host 'Langkah berikutnya (RUNBOOK R7): pasang ke HP, cek login/prediksi/catat parameter.' -ForegroundColor Cyan
Write-Host "File siap kirim: $apkPath"
