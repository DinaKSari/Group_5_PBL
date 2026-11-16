<#
.ACTION Task Scheduler
    Yang dijalankan mesin penjadwal setiap kali laptop menyala. Tugasnya cuma satu:
    memastikan rangkaian LettuGrow hidup lagi TANPA ada yang perlu login dan mengetik,
    lalu menjaga tetap hidup (loop), karena laptop ini adalah server produksi kelas kuliah.

    Daftar dipasang oleh install-autostart.ps1. Log: deploy\logs\autostart.log
#>
[CmdletBinding()]
param(
    [int]$RetrySeconds = 120,
    [int]$CheckSeconds = 60,
    [int]$WebPort = 8000
)

$ErrorActionPreference = 'Continue'

$deployDir = Split-Path -Parent $PSScriptRoot
$starter = Join-Path $deployDir 'start_tunnel.ps1'
$logDir = Join-Path $deployDir 'logs'
$logFile = Join-Path $logDir 'autostart.log'

if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

function Write-Log([string]$message) {
    $line = "{0}  {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message
    Add-Content -LiteralPath $logFile -Value $line
    Write-Host $line
}

function Test-TunnelUp {
    try {
        $api = Invoke-RestMethod -Uri 'http://127.0.0.1:4040/api/tunnels' -TimeoutSec 3
        return [bool]($api.tunnels | Where-Object { $_.public_url -like 'https://*' })
    } catch {
        return $false
    }
}

function Test-OriginUp {
    # Tunnel hidup tapi Laravel mati adalah kegagalan yang TIDAK kelihatan dari
    # /api/tunnels: ngrok tetap online dan membalas 404 HTML sendiri, jadi HP hanya
    # melihat "server mati" selamanya. Probe ini HARUS lokal: menyentuh URL publik
    # setiap $CheckSeconds menghabiskan kuota ngrok (20.000 req/bulan) untuk hal
    # yang bisa dijawab localhost. 401 JSON = rute asli, app hidup, auth aktif.
    $raw = (& curl.exe -s -o 'NUL' -w '%{http_code} %{content_type}' --max-time 5 `
        "http://127.0.0.1:$WebPort/api/sensor/latest") -join ''
    return ($raw -match '^401\s' -and $raw -match 'json')
}

function Test-InternetUp {
    foreach ($target in @('api.ngrok.com', 'www.google.com')) {
        try {
            if (Resolve-DnsName -Name $target -ErrorAction Stop) { return $true }
        } catch { Start-Sleep -Milliseconds 300 }
    }
    return $false
}

Write-Log '--- autostart berjalan (loop penjaga) ---'

while ($true) {
    if (-not (Test-InternetUp)) {
        Write-Log 'belum ada DNS keluar; tunggu internet.'
        Start-Sleep -Seconds $CheckSeconds
        continue
    }

    $tunnelUp = Test-TunnelUp
    $originUp = Test-OriginUp
    if ($tunnelUp -and $originUp) {
        Start-Sleep -Seconds $CheckSeconds
        continue
    }

    if ($tunnelUp) {
        # Yang mati origin-nya: kalau dibiarkan, tunnel publik justru menyembunyikan
        # kerusakan (ngrok balas 404, port 8000 sepi, agent tetap terlihat sehat).
        Write-Log "tunnel aktif tapi API lokal (port $WebPort) tidak balas 401 JSON -> memanggil start_tunnel.ps1"
    } else {
        Write-Log 'tunnel tidak aktif -> memanggil start_tunnel.ps1'
    }

    try {
        # Dipanggil sebagai ANAK PROSES, bukan `& $starter`: `exit 1` di dalam
        # start_tunnel.ps1 (gerbang cek sehat gagal) keluar dari seluruh scope script,
        # sehingga penjaga mati dan tidak pernah mencoba lagi sampai laptop dinyalakan
        # ulang. Sekarang penjaga gagal-nya satu kali perbaikan, lalu loop lanjut.
        $shell = Join-Path $PSHOME 'powershell.exe'
        & $shell -NoProfile -ExecutionPolicy Bypass -File $starter *>> $logFile
        if ($LASTEXITCODE -ne 0) { Write-Log "start_tunnel.ps1 keluar dengan kode $LASTEXITCODE (akan dicoba lagi)." }
        else { Write-Log 'start_tunnel.ps1 selesai (exit).' }
    } catch {
        Write-Log "start_tunnel.ps1 gagal: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $RetrySeconds
}
