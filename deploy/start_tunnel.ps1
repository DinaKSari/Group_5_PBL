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
    .\start_tunnel.ps1 -TakeOver    # izinkan skrip merebut port 8000 dari php artisan serve asing
#>
[CmdletBinding()]
param(
    [switch]$NoNgrok,
    [switch]$Status,
    [switch]$Stop,
    [switch]$MySql,
    [switch]$TakeOver,
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

function Get-PortOwner([int]$port) {
    # PID yang benar-benar memegang port. Test-Port saja tidak cukup: port bisa
    # dijawab proses lain (mis. `php artisan serve` dari jendela konsol) sehingga
    # skrip menumpang tanpa pernah sadar.
    $owners = @()
    try {
        $owners = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop |
            ForEach-Object { [int]$_.OwningProcess })
    } catch {
        $owners = @(& netstat.exe -ano 2>$null |
            Select-String ":$port\s+\S+\s+LISTENING" |
            ForEach-Object { [int](($_.ToString() -split '\s+')[-1]) })
    }
    if ($owners.Count -eq 0) { return 0 }
    return ($owners | Select-Object -First 1)
}

function Get-TrackedLaravelPids {
    # Induk dari pid file + seluruh anaknya: `artisan serve` meninggalkan anak php
    # yang justru memegang port.
    $pidFile = Join-Path $pidDir 'laravel.pid'
    if (-not (Test-Path -LiteralPath $pidFile)) { return @() }
    $root = (Get-Content -LiteralPath $pidFile -Raw).Trim()
    $ids = @([int]$root)
    try {
        $ids += @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$root" -ErrorAction Stop |
            ForEach-Object { [int]$_.ProcessId })
    } catch { }
    return $ids
}

function Get-ApiProbe([int]$port) {
    # /api/sensor/latest adalah rute API asli yang HARUS menolak tanpa token, jadi
    # 401 + JSON membuktikan tiga hal sekaligus: framework boot, routes/api.php
    # terpasang, dan middleware firebase.auth terdaftar. `/up` (health: '/up' di
    # bootstrap/app.php) hanya membuktikan yang pertama, dan tetap balas 200 HTML
    # selama app mana pun di docroot itu hidup - termasuk proses php asing.
    $raw = (& curl.exe -s -o 'NUL' -w '%{http_code} %{content_type}' `
        "http://127.0.0.1:$port/api/sensor/latest") -join ''
    $parts = @($raw -split ' ', 2)
    $code = 0
    if ($parts.Count -ge 1) { $code = [int]($parts[0] -replace '\D', '0') }
    $type = if ($parts.Count -ge 2) { $parts[1] } else { '' }
    return [pscustomobject]@{ Code = $code; Json = ($type -match 'json') }
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

function Get-LaravelOwner {
    # Mengembalikan [pscustomobject] dengan PID pemilik port + apakah itu anak yang
    # skrip ini start. Dipakai sebelum dan sesudah menyalakan Laravel.
    $ownerId = Get-PortOwner $WebPort
    [pscustomobject]@{
        Id    = $ownerId
        Mine  = ($ownerId -ne 0 -and (Get-TrackedLaravelPids) -contains $ownerId)
    }
}

function Describe-Process([int]$processId) {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$processId" -ErrorAction SilentlyContinue
    if (-not $p) { return "PID $processId (proses tidak dikenal)" }
    $line = ($p.CommandLine -replace '\s+', ' ').Trim()
    if ($line.Length -gt 110) { $line = $line.Substring(0, 110) + '...' }
    return "PID $processId = $($p.Name) [$line]"
}

$owner = Get-LaravelOwner
if ($owner.Id -ne 0 -and -not $owner.Mine) {
    if ($TakeOver) {
        Write-Step "merebut port $WebPort dari $(Describe-Process $owner.Id) (-TakeOver)"
        & taskkill.exe /PID $owner.Id /T /F 2>&1 | Out-Null
        Start-Sleep -Seconds 1
    } else {
        Write-Notice "Port $WebPort dijawab $(Describe-Process $owner.Id) - BUKAN Laravel yang skrip ini kelola."
    }
}

if ((Get-PortOwner $WebPort) -eq 0) {
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

# Cek sehat = rute API asli yang menolak tanpa token, BUKAN /up. Health check itu
# hanya membuktikan framework boot; gerbang di bawah membuktikan routes/api.php +
# middleware auth benar-benar terpasang sebelum tunnel publik dibuka.
$probe = Get-ApiProbe $WebPort
if (-not ($probe.Json -and $probe.Code -eq 401)) {
    $owner = Get-LaravelOwner
    $who = if ($owner.Mine) { 'Laravel milik skrip ini' } else { Describe-Process $owner.Id }
    Stop-WithError "API tidak balas 401 JSON di port $WebPort (dapat: $($probe.Code), content-type bukan JSON) dari $who. Kemungkinan yang menjawab adalah halaman error/Laragon, atau APP_DEBUG masih aktif. Tunnel TIDAK dibuka supaya HP tidak menumpang server setengah hidup. Lihat deploy\logs\laravel.error.log; untuk mengusir pemakai port: .\start_tunnel.ps1 -TakeOver"
}
Write-Ok "API terverifikasi: /api/sensor/latest balas $($probe.Code) JSON"

$owner = Get-LaravelOwner
if (-not $owner.Mine) {
    Write-Notice "Yang menjawab port $WebPort adalah $(Describe-Process $owner.Id). Tunnel akan menumpang jendela itu: kalau jendela ditutup, penjaga (letugrow-tunnel.ps1) melihat API lokal mati dan menyalakan Laravel sendiri. Mau skrip ini yang memegang port? tutup proses itu lalu jalankan ulang, atau pakai -TakeOver."
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
Write-Host '  Hentikan       : .\start_tunnel.ps1 -Stop  (MySQL tetap hidup; -Stop -MySql sekalian)' -ForegroundColor DarkGray
Write-Host ''
