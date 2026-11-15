<#
    Membuat keystore untuk APK rilis LettuGrow + menulis android/key.properties.

    Passphrase diketik di prompt tersembunyi (Read-Host -AsSecureString) dan
    diteruskan ke keytool HANYA lewat environment variable proses anak
    (-storepass:env). Nilai itu tidak pernah tercetak di layar, tidak masuk
    command line / riwayat shell, dan tidak pernah perlu dikirim ke chat.

    Contoh:
      powershell -ExecutionPolicy Bypass -File tool\make_keystore.ps1
      powershell -ExecutionPolicy Bypass -File tool\make_keystore.ps1 -Alias letugrow2 -Force
#>
param(
    [string]$OutDir = (Join-Path $env:USERPROFILE '.android'),
    [string]$KeyStoreName = 'letugrow-release.keystore',
    [string]$Alias = 'letugrow',
    [int]$ValidityDays = 10000,
    [string]$DName = 'CN=LettuGrow, OU=Smart Farming, O=Kelompok 5, C=ID',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$smartFarmingDir = Split-Path -Parent $PSScriptRoot
$androidDir = Join-Path $smartFarmingDir 'android'
$keyPropsPath = Join-Path $androidDir 'key.properties'

function Write-Step([string]$Message) { Write-Host "== $Message" -ForegroundColor Cyan }
function Write-Ok([string]$Message) { Write-Host "[OK]  $Message" -ForegroundColor Green }
function Stop-WithError([string]$Message) {
    Write-Host "[X]   $Message" -ForegroundColor Red
    exit 1
}

function ConvertTo-PlainString([System.Security.SecureString]$Value) {
    $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
    }
}

function Find-KeyTool {
    $candidates = @()
    if ($env:JAVA_HOME) { $candidates += (Join-Path $env:JAVA_HOME 'bin/keytool.exe') }
    $candidates += 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe'
    $candidates += 'C:\Program Files\Android\Android Studio1\jbr\bin\keytool.exe'
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) { return $candidate }
    }
    $fromPath = Get-Command keytool.exe -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    return $null
}

function Test-PathIgnoredByGit([string]$RepoRelative, [string]$AbsolutePath) {
    # File rahasia yang TERLACAK oleh git adalah kecelakaan yang menunggu terjadi.
    $tracked = & git -C $smartFarmingDir ls-files --error-unmatch $RepoRelative 2>$null
    if ($LASTEXITCODE -eq 0) {
        Stop-WithError "$AbsolutePath terlacak git. Hentikan dulu, jalankan: git rm --cached $RepoRelative"
    }
    & git -C $smartFarmingDir check-ignore -q $RepoRelative
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$AbsolutePath belum dicakup .gitignore. Cek sebelum lanjut."
    } else {
        Write-Ok "$RepoRelative ter-gitignore."
    }
}

Write-Step 'Mencari keytool'
$keyTool = Find-KeyTool
if (-not $keyTool) {
    Stop-WithError @'
keytool tidak ditemukan. Skrip ini butuh JDK yang dipakai Android Studio.
Coba salah satu:
  - biarkan Android Studio terpasang di C:\Program Files\Android\Android Studio
  - set $env:JAVA_HOME ke folder JDK (mis. C:\Program Files\Java\jdk-17)
'@
}
Write-Ok "keytool: $keyTool"

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}
$keyStorePath = Join-Path $OutDir $KeyStoreName

Write-Step 'Keystore'
if (Test-Path $keyStorePath) {
    if (-not $Force) {
        Stop-WithError "$keyStorePath sudah ada. Membuat ulang = APK lama tidak bisa di-upgrade. `n         Yakin? jalankan ulang dengan -Force (hapus dulu salinan cadangan di luar laptop kalau memang perlu)."
    }
    Remove-Item $keyStorePath -Force
    Write-Warning 'Keystore lama dihapus karena -Force.'
}
Write-Host "Tujuan : $keyStorePath"
Write-Host "Alias  : $Alias  (validitas $ValidityDays hari)"

Write-Step 'Passphrase (tidak akan ditampilkan)'
$pass1 = Read-Host 'Passphrase keystore, minimal 8 karakter' -AsSecureString
$pass2 = Read-Host 'Ulangi passphrase yang sama' -AsSecureString
$plain = ConvertTo-PlainString $pass1
if ($plain -ne (ConvertTo-PlainString $pass2)) {
    $plain = $null
    Stop-WithError 'Ketik ulang passphrase tidak sama. Tidak ada file yang dibuat.'
}
if ($plain.Length -lt 8) {
    $plain = $null
    Stop-WithError 'Passphrase terlalu pendek (minimal 8 karakter).'
}
$plain = $null

Write-Step 'Membuat pasangan kunci'
$env:LTG_KEYSTORE_PASS = ConvertTo-PlainString $pass1
try {
    & $keyTool '-genkeypair' '-v' '-storetype' 'PKCS12' `
        '-keystore' $keyStorePath '-alias' $Alias `
        '-keyalg' 'RSA' '-keysize' '2048' '-validity' "$ValidityDays" `
        '-dname' $DName '-storepass:env' 'LTG_KEYSTORE_PASS' '-keypass:env' 'LTG_KEYSTORE_PASS'
    if ($LASTEXITCODE -ne 0) {
        Stop-WithError "keytool gagal (exit $LASTEXITCODE). Tidak ada yang diubah selain file separuh jadi - hapus $keyStorePath bila perlu."
    }
} finally {
    Remove-Item Env:LTG_KEYSTORE_PASS -ErrorAction SilentlyContinue
}
Write-Ok 'Pasangan kunci dibuat.'

# Verifikasi keystore bisa dibuka ulang - passphrase tetap lewat environment,
# bukan argumen baris perintah.
$env:LTG_KEYSTORE_PASS = ConvertTo-PlainString $pass1
try {
    $listing = & $keyTool '-list' '-keystore' $keyStorePath '-alias' $Alias '-storepass:env' 'LTG_KEYSTORE_PASS' 2>&1
    if ($LASTEXITCODE -ne 0 -or -not ($listing -match [regex]::Escape($Alias))) {
        Stop-WithError 'Keystore tidak bisa dibaca ulang. Ulangi tanpa -Force.'
    }
} finally {
    Remove-Item Env:LTG_KEYSTORE_PASS -ErrorAction SilentlyContinue
}
Write-Ok 'Keystore terbaca ulang.'

Write-Step 'Menulis key.properties'
$storeFileForGradle = $keyStorePath.Replace('\', '/')
$body = @(
    '# Dibuat tool/make_keystore.ps1. RAHASIA - jangan commit, jangan kirim ke chat.',
    '# Passphrase hanya ada di kepala kalian + file ini (sudah ter-gitignore).',
    "storeFile=$storeFileForGradle",
    "storeType=PKCS12",
    "keyAlias=$Alias",
    "storePassword=$(ConvertTo-PlainString $pass1)",
    "keyPassword=$(ConvertTo-PlainString $pass1)"
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText($keyPropsPath, $body + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))
Write-Ok "key.properties: $keyPropsPath"

Write-Step 'Memastikan tidak ada yang bocor ke git'
Test-PathIgnoredByGit 'android/key.properties' $keyPropsPath
if ($keyStorePath.StartsWith($smartFarmingDir, [StringComparison]::OrdinalIgnoreCase)) {
    $relative = $keyStorePath.Substring($smartFarmingDir.Length).TrimStart('\', '/')
    Test-PathIgnoredByGit ($relative -replace '\\', '/') $keyStorePath
} else {
    Write-Ok 'Keystore berada di luar repo.'
}

Write-Step 'CADANGKAN DI LUAR LAPTOP (wajib)'
Write-Host "Salin file ini ke flashdisk / cloud pribadi SEKARANG:" -ForegroundColor Yellow
Write-Host "    $keyStorePath" -ForegroundColor Yellow
Write-Host "Tanpa cadangan, kehilangan laptop = tidak bisa lagi menerbitkan"
Write-Host "APK yang bisa dipasang di HP user yang sudah ada."
Read-Host 'Tekan ENTER setelah salinan di luar laptop dibuat' | Out-Null

Write-Host ''
Write-Host 'Selesai. Lanjut build rilis:' -ForegroundColor Green
Write-Host '  powershell -ExecutionPolicy Bypass -File tool\build_release.ps1'
Write-Host ''
Write-Host 'Kabari hanya PATH keystore + alias ke pengelola repo. JANGAN passphrase-nya.' -ForegroundColor Cyan
