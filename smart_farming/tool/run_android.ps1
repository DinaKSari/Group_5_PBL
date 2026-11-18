<#
    Menjalankan aplikasi ke perangkat Android lewat USB.

    Port forwarding ADB membuat HP mengakses laptop lewat 127.0.0.1:8000,
    sehingga koneksi backend tidak bergantung pada IP laptop maupun kondisi Wi-Fi
    (termasuk jaringan yang memblokir komunikasi antar perangkat).

    Sebelum launch, skrip memeriksa Laravel (8000) dan Flask ML (5000). Tanpa Flask,
    halaman prediksi gagal dengan 503 "Layanan prediksi ML tidak dapat dihubungi".

    Contoh:
      .\tool\run_android.ps1                    # cek layanan, lalu jalan
      .\tool\run_android.ps1 -StartBackend      # nyalakan layanan yang mati otomatis
      .\tool\run_android.ps1 -CheckOnly         # periksa layanan saja
#>
param(
    [string]$Device = '',
    [int]$Port = 8000,
    [int]$MlPort = 5000,
    [switch]$StartBackend,
    [switch]$CheckOnly
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$backendDir = Join-Path $repoRoot 'backend'
$mlApiDir = Join-Path (Split-Path -Parent $repoRoot) 'ML/api'

function Test-PortListening([int]$Port) {
    [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

function Wait-PortListening([int]$Port, [int]$Seconds) {
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-PortListening $Port) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Start-ServiceWindow([string]$Title, [string]$WorkDir, [string]$Command, [int]$Port) {
    if (-not (Test-Path $WorkDir)) {
        Write-Warning "Direktori $WorkDir tidak ditemukan, tidak bisa menyalakan $Title."
        return
    }
    Start-Process powershell -ArgumentList @(
        '-NoExit', '-Command',
        "Set-Location '$WorkDir'; Write-Host '== $Title ==' ; $Command"
    ) | Out-Null
    if (Wait-PortListening $Port 25) {
        Write-Host "  $Title aktif pada port $Port."
    } else {
        Write-Warning "  $Title belum mendengarkan port $Port. Cek jendela $Title untuk error-nya."
    }
}

# --- [1/3] Layanan backend
foreach ($svc in @(
    @{ Name = 'Flask ML'; Port = $MlPort; Dir = $mlApiDir; Cmd = 'python app.py' },
    @{ Name = 'Laravel API'; Port = $Port; Dir = $backendDir; Cmd = "php artisan serve --port=$Port" }
)) {
    if (Test-PortListening $svc.Port) {
        Write-Host "[OK]  $($svc.Name) mendengarkan port $($svc.Port)"
    } elseif ($StartBackend) {
        Write-Host "[..]  Menyalakan $($svc.Name) ..."
        Start-ServiceWindow $svc.Name $svc.Dir $svc.Cmd $svc.Port
    } else {
        Write-Host "[--]  $($svc.Name) MATI (port $($svc.Port))." -ForegroundColor Yellow
        Write-Host "      Jalankan: cd `"$($svc.Dir)`" ; $($svc.Cmd)"
    }
}

if ($CheckOnly) { return }

# --- [2/3] Perangkat + port forwarding
$serial = if ($Device) { $Device } else {
    $first = (adb devices) | Where-Object { $_ -match '\sdevice$' } | Select-Object -First 1
    if (-not $first) { throw 'Tidak ada perangkat Android yang terhubung lewat ADB.' }
    ($first -split '\s+')[0]
}
Write-Host "Perangkat : $serial"
adb -s $serial reverse "tcp:$Port" "tcp:$Port" | Out-Null
Write-Host "Forwarding: localhost:$Port (HP) -> localhost:$Port (laptop)"

# --- [3/3] Launch
Push-Location $repoRoot
try {
    flutter run -d $serial
} finally {
    Pop-Location
}
