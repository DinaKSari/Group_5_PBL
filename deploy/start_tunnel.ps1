<#
.SYNOPSIS
    Nyalakan seluruh rangkaian LettuGrow: MySQL -> Flask ML -> Laravel -> ngrok.

.DESCRIPTION
    Dirancang untuk laptop kelas "server kuliah" yang tiap hari dimatikan tanpa prosesi.
    Semua langkah idempoten: port yang sudah hidup dilewati, jadi skrip ini aman dijalankan
    berulang, termasuk di atas Laragon yang sudah jalan. Log proses anak masuk ke deploy\logs\.

.EXAMPLE
    .\start_tunnel.ps1              # nyalakan semuanya sampai tunnel publik aktif
    .\start_tunnel.ps1 -NoNgrok     # lokal saja (HP via adb reverse / Wi-Fi)
    .\start_tunnel.ps1 -Status      # lihat apa yang hidup + URL publik, tanpa mengubah apa pun
    .\start_tunnel.ps1 -Stop        # hentikan Laravel/Flask/ngrok milik skrip ini (MySQL dibiarkan)
    .\start_tunnel.ps1 -Stop -MySql # ... dan MySQL yang tadi dinyalakan skrip ini
#>
[CmdletBinding()]
param(
    [switch]$NoNgrok,
    [switch]$Status,
    [switch]$Stop,
    [switch]$MySql,
    [int]$WebPort = 8000,
    [int]$MlPort = 5000,
    [int]$MysqlPort = 3306,
    [int]$Workers = 4
)

$ErrorActionPreference = 'Stop'

$deployDir = $PSScriptRoot
$root = Split-Path -Parent $deployDir
$backendDir = Join-Path $root 'smart_farming\backend'
$mlDir = Join-Path $root 'ML\api'
$logDir = Join-Path $deployDir 'logs'
$pidDir = Join-Path $logDir 'pids'

# Path yang hanya berlaku di mesin ini ada di tunnel.config.json (tidak masuk git;
# tunnel.config.example.json yang masuk git).
$config = @{}
$configFile = Join-Path $deployDir 'tunnel.config.json'
if (Test-Path -LiteralPath $configFile) {
    foreach ($entry in (Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json).PSObject.Properties) {
        $config[$entry.Name] = $entry.Value
    }
}

function Write-Step([string]$message) { Write-Host "  .. $message" -ForegroundColor DarkGray }
function Write-Ok([string]$message) { Write-Host "[OK] $message" -ForegroundColor Green }
function Write-Notice([string]$message) { Write-Host "[!!] $message" -ForegroundColor Yellow }
function Stop-WithError([string]$message) { Write-Host "[X] $message" -ForegroundColor Red; exit 1 }

function Test-Port([int]$port, [int]$timeoutMs = 500) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connect = $client.ConnectAsync('127.0.0.1', $port)
        return $connect.Wait($timeoutMs) -and $client.Connected
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Wait-Port([int]$port, [int]$seconds) {
    for ($i = 0; $i -lt ($seconds * 2); $i++) {
        if (Test-Port $port) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

function Get-EnvValue([string]$path, [string]$key) {
    if (-not (Test-Path -LiteralPath $path)) { return $null }
    foreach ($line in (Get-Content -LiteralPath $path)) {
        if ($line -match "^\s*$([regex]::Escape($key))\s*=\s*(.*?)\s*$") { return $Matches[1].Trim('"') }
    }
    return $null
}

function Resolve-Tool([string]$name, [string]$fallbackGlob) {
    if ($config.ContainsKey($name) -and (Test-Path -LiteralPath $config[$name])) { return $config[$name] }
    $found = Get-Command $name -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    if ($fallbackGlob) {
        $hit = Get-ChildItem -Path $fallbackGlob -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Start-Detached([string]$file, [string]$arguments, [string]$workDir, [string]$tag) {
    if (-not (Test-Path -LiteralPath $pidDir)) { New-Item -ItemType Directory -Force -Path $pidDir | Out-Null }
    $process = Start-Process -FilePath $file -ArgumentList $arguments -WorkingDirectory $workDir `
        -WindowStyle Hidden -PassThru `
        -RedirectStandardOutput (Join-Path $logDir "$tag.log") `
        -RedirectStandardError (Join-Path $logDir "$tag.error.log")
    Set-Content -LiteralPath (Join-Path $pidDir "$tag.pid") -Value $process.Id
    return $process
}

function Stop-Tracked([string]$tag) {
    $pidFile = Join-Path $pidDir "$tag.pid"
    if (-not (Test-Path -LiteralPath $pidFile)) { return }
    $targetId = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    if (-not (Get-Process -Id $targetId -ErrorAction SilentlyContinue)) { return }
    # /T (tree) wajib: `artisan serve` dengan PHP_CLI_SERVER_WORKERS meninggalkan anak php
    # yang tetap mendengar di 8000 kalau hanya proses induknya yang dimatikan.
    & taskkill.exe /PID $targetId /T /F 2>&1 | Out-Null
    Start-Sleep -Milliseconds 300
    $stillUp = Get-Process -Id $targetId -ErrorAction SilentlyContinue
    if ($stillUp) { Write-Notice "$tag tidak bisa dihentikan (PID $targetId masih hidup)" }
    else { Write-Ok "$tag dihentikan beserta child-process-nya (PID $targetId)" }
}

function Get-NgrokUrl {
    if (-not (Test-Port 4040 300)) { return $null }
    try {
        $api = Invoke-RestMethod -Uri 'http://127.0.0.1:4040/api/tunnels' -TimeoutSec 3
        $https = $api.tunnels | Where-Object { $_.public_url -like 'https://*' } | Select-Object -First 1
        if ($https) { return $https.public_url }
    } catch { return $null }
    return $null
}

function Show-Status {
    Write-Host ''
    Write-Host 'Status rangkaian LettuGrow' -ForegroundColor Cyan
    foreach ($probe in @(
            @{ Port = $MysqlPort; Name = 'MySQL' },
            @{ Port = $MlPort; Name = 'Flask ML' },
            @{ Port = $WebPort; Name = 'Laravel' },
            @{ Port = 4040; Name = 'ngrok agent' })) {
        if (Test-Port $probe.Port) {
            Write-Ok "$($probe.Name) hidup di port $($probe.Port)"
        } else {
            Write-Host "[--] $($probe.Name) tidak aktif" -ForegroundColor DarkGray
        }
    }
    $url = Get-NgrokUrl
    if ($url) { Write-Ok "URL publik: $url" } else { Write-Host '[--] tidak ada tunnel aktif' -ForegroundColor DarkGray }
    Write-Host ''
}

# ---------------------------------------------------------------- Stop / Status

if ($Stop) {
    foreach ($tag in @('ngrok', 'laravel', 'flask')) { Stop-Tracked $tag }
    if ($MySql) {
        # Matinya MySQL pakai mysqladmin, BUKAN Stop-Process: kill paksa adalah persis
        # skenario "laptop mati tidak bersih" yang kita hindari dengan pindah ke MySQL.
        $admin = Resolve-Tool 'mysqladmin.exe' 'C:\laragon\bin\mysql\*\bin\mysqladmin.exe'
        if (-not $admin) {
            Write-Notice 'mysqladmin.exe tidak ditemukan; MySQL dibiarkan hidup.'
        } else {
            & $admin -u root -h 127.0.0.1 shutdown 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Ok 'MySQL berhenti dengan rapi (shutdown)' }
            else { Write-Notice 'mysqladmin menolak shutdown (mungkin password root sudah diisi).' }
        }
        Remove-Item -LiteralPath (Join-Path $pidDir 'mysql.pid') -Force -ErrorAction SilentlyContinue
    } else {
        Write-Notice 'MySQL tidak dihentikan (mungkin dipakai proyek Laragon lain). Pakai -Stop -MySql untuk mematikannya.'
    }
    exit 0
}

if ($Status) { Show-Status; exit 0 }

# ------------------------------------------------------------------ Prasyarat

Write-Host ''
Write-Host 'LettuGrow - menyalakan server + tunnel' -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }

$envFile = Join-Path $backendDir '.env'
if (-not (Test-Path -LiteralPath $envFile)) {
    Stop-WithError "$envFile tidak ada. Salin .env.example ke .env lalu isi kuncinya."
}

$secret = Get-EnvValue $envFile 'FLASK_ML_SHARED_SECRET'
if ([string]::IsNullOrWhiteSpace($secret)) {
    Stop-WithError 'FLASK_ML_SHARED_SECRET kosong di backend/.env. Laravel balas 503 dan Flask menolak semua /predict. Nilainya harus sama persis dengan ML_SHARED_SECRET milik Flask - di sini Flask mengambilnya dari .env yang sama, jadi cukup satu tempat.'
}

if ((Get-EnvValue $envFile 'APP_DEBUG') -ne 'false') {
    Stop-WithError 'APP_DEBUG masih true. Tunnel publik + stack trace = config dan isi .env bocor ke HP user. Set APP_DEBUG=false di backend/.env lebih dulu.'
}

$php = Resolve-Tool 'php.exe' 'C:\laragon\bin\php\*\php.exe'
if (-not $php) { Stop-WithError 'php.exe tidak ditemukan. Set "php.exe" di deploy\tunnel.config.json.' }

$python = Resolve-Tool 'python.exe' 'C:\laragon\bin\python\*\python.exe'
if (-not $python) { Stop-WithError 'python.exe tidak ditemukan (dipakai Flask ML).' }

# -------------------------------------------------------------------- 1. MySQL

if (Test-Port $MysqlPort) {
    Write-Ok "MySQL sudah hidup di port $MysqlPort (dilewati)"
} else {
    $mysqld = Resolve-Tool 'mysqld.exe' 'C:\laragon\bin\mysql\*\bin\mysqld.exe'
    if (-not $mysqld) { Stop-WithError 'mysqld.exe tidak ditemukan. Set "mysqld.exe" di deploy\tunnel.config.json.' }
    Write-Step 'menyalakan MySQL (bukan service, jadi dijalankan langsung seperti Laragon)'
    # Tanpa --defaults-file: my.ini Laragon ada di basedir dan discovery standar menemukannya.
    $mysqlLog = Join-Path $logDir 'mysqld.log'
    $process = Start-Process -FilePath $mysqld -ArgumentList "--log-error=`"$mysqlLog`"" `
        -WindowStyle Hidden -PassThru
    Set-Content -LiteralPath (Join-Path $pidDir 'mysql.pid') -Value $process.Id
    if (-not (Wait-Port $MysqlPort 40)) {
        Stop-WithError "MySQL tidak kunjung mendengar di $MysqlPort. Lihat $mysqlLog"
    }
    Write-Ok "MySQL siap (PID $($process.Id))"
}

# ------------------------------------------------------------------ 2. Flask ML

if (Test-Port $MlPort) {
    Write-Ok "Flask ML sudah hidup di port $MlPort (dilewati)"
} else {
    Write-Step 'menyalakan Flask ML'
    # Diwariskan ke proses anak. Satu sumber kebenaran: .env Laravel.
    $env:ML_SHARED_SECRET = $secret
    Start-Detached $python 'app.py' $mlDir 'flask' | Out-Null
    if (-not (Wait-Port $MlPort 60)) {
        Stop-WithError "Flask ML tidak kunjung mendengar di $MlPort. Lihat deploy\logs\flask.error.log (model belum dilatih, atau versi numpy/xgboost tidak cocok dengan artefak .joblib)."
    }
    try {
        $health = Invoke-RestMethod -Uri "http://127.0.0.1:$MlPort/health" -TimeoutSec 5
        if ($health.status -ne 'ok') { Write-Notice "Flask balas status '$($health.status)': model regresi belum ada." }
    } catch {
        Write-Notice '/health Flask tidak terbaca, lanjut.'
    }
    Write-Ok 'Flask ML siap'
}

# ------------------------------------------------------------------ 3. Laravel

if (Test-Port $WebPort) {
    Write-Ok "Laravel sudah hidup di port $WebPort (dilewati)"
} else {
    Write-Step 'menyalakan Laravel'
    # --host 127.0.0.1 (bukan 0.0.0.0 seperti run_all.bat): satu-satunya pintu keluar
    # yang sah adalah ngrok. --no-reload diperlukan supaya PHP_CLI_SERVER_WORKERS dipatuhi,
    # dan mode produksi-emulator memang tidak perlu watcher file.
    $env:PHP_CLI_SERVER_WORKERS = "$Workers"
    Start-Detached $php "artisan serve --host=127.0.0.1 --port=$WebPort --no-reload" $backendDir 'laravel' | Out-Null
    if (-not (Wait-Port $WebPort 30)) {
        Stop-WithError "Laravel tidak kunjung mendengar di $WebPort. Lihat deploy\logs\laravel.error.log"
    }
    Write-Ok "Laravel siap di http://127.0.0.1:$WebPort ($Workers worker)"
}

try {
    $up = Invoke-WebRequest -Uri "http://127.0.0.1:$WebPort/up" -UseBasicParsing -TimeoutSec 8
    if ($up.StatusCode -ne 200) { Write-Notice "/up balas $($up.StatusCode)" }
} catch {
    Stop-WithError "Laravel mendengar di $WebPort tapi /up gagal: $($_.Exception.Message)"
}

# Guard terakhir: pastikan tidak ada detail exception yang ikut mengalir ke publik.
$leakProbe = (& curl.exe -s -X POST -H 'Content-Type: application/json' -d '{}' `
    "http://127.0.0.1:$WebPort/api/predict") -join ' '
if ($leakProbe -match '"exception"|"file"|"trace"') {
    Stop-WithError 'Respons API memuat detail exception. APP_DEBUG belum benar-benar nonaktif - jalankan: php artisan config:clear'
}

# -------------------------------------------------------------------- 4. ngrok

if ($NoNgrok) {
    Write-Host ''
    Write-Notice 'Tanpa tunnel (-NoNgrok): hanya adb reverse / jaringan lokal yang bisa mengakses.'
    exit 0
}

$ngrok = Resolve-Tool 'ngrok.exe' 'C:\laragon\bin\ngrok\ngrok.exe'
if (-not $ngrok) { Stop-WithError 'ngrok.exe tidak ditemukan. Set "ngrok.exe" di deploy\tunnel.config.json.' }

$ngrokConfig = $config['ngrok.yml']
if (-not $ngrokConfig) {
    $candidate = Join-Path $env:LOCALAPPDATA 'ngrok\ngrok.yml'
    if (Test-Path -LiteralPath $candidate) { $ngrokConfig = $candidate }
}
if ($ngrokConfig -and -not (Test-Path -LiteralPath $ngrokConfig)) {
    Stop-WithError "ngrok.yml tidak ada: $ngrokConfig"
}

if (Test-Port 4040) {
    Write-Ok 'ngrok agent sudah jalan (dilewati)'
} else {
    Write-Step 'menyalakan ngrok http'
    $ngrokArgs = "http $WebPort --log=`"$(Join-Path $logDir 'ngrok.log')`" --log-format=json"
    if ($ngrokConfig) { $ngrokArgs += " --config=`"$ngrokConfig`"" }
    Start-Detached $ngrok $ngrokArgs $deployDir 'ngrok' | Out-Null
    if (-not (Wait-Port 4040 25)) {
        Stop-WithError "ngrok tidak membuka API lokal 4040 (authtoken belum dipasang?). Lihat deploy\logs\ngrok.error.log"
    }
}

$url = $null
for ($i = 0; $i -lt 10 -and -not $url; $i++) {
    $url = Get-NgrokUrl
    if (-not $url) { Start-Sleep -Seconds 1 }
}
if (-not $url) { Stop-WithError 'Tunnel aktif tapi URL publik tidak terbaca dari API ngrok (port 4040).' }

Set-Content -LiteralPath (Join-Path $deployDir 'last-url.txt') -Value "$url/api"
Write-Host ''
Write-Host "  API publik     : $url/api" -ForegroundColor Green
Write-Host "  Remote Config  : isi api_base_url = $url/api" -ForegroundColor DarkGray
Write-Host '  Hentikan       : .\stop_tunnel.ps1   (atau .\start_tunnel.ps1 -Stop)' -ForegroundColor DarkGray
Write-Host ''
