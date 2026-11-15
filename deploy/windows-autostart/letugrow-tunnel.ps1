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
    [int]$CheckSeconds = 60
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

    if (Test-TunnelUp) {
        Start-Sleep -Seconds $CheckSeconds
        continue
    }

    Write-Log 'tunnel tidak aktif -> memanggil start_tunnel.ps1'
    try {
        & $starter *>> $logFile
        Write-Log 'start_tunnel.ps1 selesai (exit).'
    } catch {
        Write-Log "start_tunnel.ps1 gagal: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $RetrySeconds
}
