@echo off
rem Wrapper klik-ganda untuk deploy\start_tunnel.ps1 (PowerShell tidak bisa di-double-click langsung).
rem Semua logika ada di start_tunnel.ps1 - file ini cuma memilih mode.
setlocal
set "SCRIPT=%~dp0start_tunnel.ps1"

if /i "%~1"=="stop"   goto stop
if /i "%~1"=="status" goto status
goto start

:start
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
goto done

:stop
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Stop
goto done

:status
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Status
goto done

:done
echo.
pause
