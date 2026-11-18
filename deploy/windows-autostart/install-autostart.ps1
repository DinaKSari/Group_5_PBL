<#
.SYNOPSIS
    Daftarkan rangkaian LettuGrow agar hidup sendiri setiap kali laptop menyala.

.DESCRIPTION
    Menutup risiko "ngrok hidup, backend mati" (PLAN 2.5.2): setelah boot, tanpa login
    dan tanpa mengetik apa pun, MySQL -> Flask -> Laravel -> ngrok dinyalakan berurutan
    dan dijaga tetap hidup oleh letugrow-tunnel.ps1.

    Butuh hak Administrator sekali saja (Task Scheduler tingkat sistem).
    Jalankan dari PowerShell biasa: skrip ini akan minta UAC dan melanjutkan sendiri.

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\install-autostart.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File .\install-autostart.ps1 -VerifyOnly
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'LettuGrow Tunnel',
    [switch]$VerifyOnly
)

$ErrorActionPreference = 'Stop'

$autostartDir = $PSScriptRoot
$deployDir = Split-Path -Parent $autostartDir
$runner = Join-Path $autostartDir 'letugrow-tunnel.ps1'
$configFile = Join-Path $deployDir 'tunnel.config.json'

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Path -LiteralPath $runner)) { throw "Runner tidak ditemukan: $runner" }

# ------------------------------------------------------------------ self-elevate

if (-not (Test-IsAdmin)) {
    Write-Host 'Butuh hak Administrator untuk mendaftarkan task saat boot -> minta UAC...' -ForegroundColor Yellow
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-TaskName', $TaskName)
    if ($VerifyOnly) { $psArgs += '-VerifyOnly' }
    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $psArgs
    exit 0
}

# ------------------------------------------------------------------------ verify

if ($VerifyOnly) {
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (-not $task) { Write-Host "Task '$TaskName' belum terdaftar." -ForegroundColor Yellow; exit 1 }
    $task | Select-Object TaskName, State | Format-List
    (Get-ScheduledTaskInfo -TaskName $TaskName) | Select-Object LastRunTime, LastTaskResult, NextRunTime | Format-List
    exit 0
}

# ------------------------------------------------- config mesin (ngrok.yml SYSTEM)

# Task jalan sebagai SYSTEM, jadi $env:LOCALAPPDATA pointing ke systemprofile dan
# authtoken ngrok kalian tidak akan ketemu. Kunci ngrok adalah user yang sedang login,
# jadi path-nya dikunci sekarang ke tunnel.config.json (file ini tidak masuk git).
$ngrokYml = Join-Path $env:LOCALAPPDATA 'ngrok\ngrok.yml'
if (Test-Path -LiteralPath $ngrokYml) {
    $existing = @{}
    if (Test-Path -LiteralPath $configFile) {
        foreach ($entry in (Get-Content -LiteralPath $configFile -Raw | ConvertFrom-Json).PSObject.Properties) {
            $existing[$entry.Name] = $entry.Value
        }
    }
    $existing['ngrok.yml'] = $ngrokYml
    $existing | ConvertTo-Json | Set-Content -LiteralPath $configFile -Encoding UTF8
    Write-Host "Ngrok config untuk task: $ngrokYml" -ForegroundColor Green
} else {
    Write-Warning "$ngrokYml tidak ditemukan. Jalankan 'ngrok config add-authtoken <token>' sekali sebagai user ini, lalu ulangi instalasi."
}

# ------------------------------------------------------------------------ daftar

# -Argument di beberapa build TaskScheduler module hanya menerima satu string
# (array -> ParameterArgumentTransformationError), jadi rangkai manual.
# Path runner mengandung spasi -> wajib diberi kutip di dalam string itu sendiri.
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument ('-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}"' -f $runner) `
    -WorkingDirectory $autostartDir

$trigger = New-ScheduledTaskTrigger -AtStartup

# SYSTEM + ServiceAccount = jalan tanpa ada yang login. Highest supaya bisa dengar port
# dan menulis di folder Laragon.
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -StartWhenAvailable -MultipleInstances IgnoreNew -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 2) `
    -ExecutionTimeLimit (New-TimeSpan -Seconds 0)

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal `
    -Settings $settings -Description 'LettuGrow: nyalakan MySQL, Flask ML, Laravel, dan ngrok saat boot; jaga tetap hidup.' -Force | Out-Null

Write-Host ''
Write-Host "Task terdaftar: $TaskName" -ForegroundColor Green
Write-Host 'Uji sekarang (tanpa reboot):' -ForegroundColor Cyan
Write-Host "  Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "  Get-Content '$(Join-Path $deployDir 'logs\autostart.log')' -Tail 20"
Write-Host 'Bongkar lagi: .\uninstall-autostart.ps1' -ForegroundColor DarkGray
Write-Host ''
Write-Warning 'Mulai sekarang, siapa pun yang menyalakan laptop ini akan langsung menyalakan server publik. Pastikan APP_DEBUG=false dan admin panel sudah diganti passwordnya (RUNBOOK R10).'
