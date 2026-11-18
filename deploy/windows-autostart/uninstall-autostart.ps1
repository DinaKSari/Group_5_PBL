<#
.SYNOPSIS
    Bongkar autostart LettuGrow (task + proses yang sedang dijaga).
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\uninstall-autostart.ps1
#>
[CmdletBinding()]
param(
    [string]$TaskName = 'LettuGrow Tunnel',
    [switch]$KeepServices
)

$ErrorActionPreference = 'Stop'

$deployDir = Split-Path -Parent $PSScriptRoot
$starter = Join-Path $deployDir 'start_tunnel.ps1'

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Ok([string]$message) { Write-Host "[OK] $message" -ForegroundColor Green }

if (-not (Test-IsAdmin)) {
    Write-Host 'Butuh hak Administrator untuk menghapus task boot -> minta UAC...' -ForegroundColor Yellow
    $psArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-TaskName', $TaskName)
    if ($KeepServices) { $psArgs += '-KeepServices' }
    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList $psArgs
    exit 0
}

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host "Task '$TaskName' memang tidak terdaftar." -ForegroundColor Yellow
} else {
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Ok "Task '$TaskName' dihapus."
}

if (-not $KeepServices) {
    # Loop penjaga mati, tapi MySQL/Laravel/Flask/ngrok yang sudah terlanjur hidup
    # tetap melayani - matikan juga supaya benar-benar offline.
    & $starter -Stop
}

Write-Host 'Selesai. Laptop bukan server publik lagi sampai install-autostart.ps1 dijalankan lagi.' -ForegroundColor Green
