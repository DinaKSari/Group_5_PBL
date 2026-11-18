@echo off
REM run_all.bat - nyalakan 3 layanan sekaligus untuk demo final:
REM   1. Flask ML      (port 5000, hanya diakses Laravel)
REM   2. Laravel API   (0.0.0.0:8000, diakses Flutter dari perangkat fisik)
REM   3. (opsional) flutter run / flutter install untuk perangkat.
REM
REM Jalankan dari root repo:  .\run_all.bat [flutter|apk|none]
REM Default  = "flutter" (bangun debug & jalankan ke perangkat yang tersambung).
REM   "apk"   = install rilis APK (build dulu sekali).
REM   "none"  = nyalakan backend saja, tanpa Flutter.

setlocal enabledelayedexpansion
set ROOT=%~dp0
set MODE=%1
if "%MODE%"=="" set MODE=flutter

echo ========================================
echo  Kelompok 5 - Smart Farming Selada
echo  Mode: %MODE%
echo ========================================

REM --- [0/3] (opsional) latih ulang model ML.
REM Uncomment bila perlu: call python "%ROOT%ML\api\train.py"

echo.
echo [1/3] Menyalakan Flask ML (http://127.0.0.1:5000) ...

REM Flask menolak /predict tanpa header X-ML-Token yang sama dengan nilai di
REM backend\.env (FLASK_ML_SHARED_SECRET). Jadi rahasia itu HARUS di-export ke
REM jendela Flask, tidak bisa dilewatkan.
set ML_SECRET=
for /f "usebackq tokens=1,* delims==" %%A in (`findstr /b /c:"FLASK_ML_SHARED_SECRET=" "%ROOT%smart_farming\backend\.env"`) do set ML_SECRET=%%B
if "%ML_SECRET%"=="" (
    echo   ERROR: FLASK_ML_SHARED_SECRET tidak ada / kosong di smart_farming\backend\.env
    echo   Semua prediksi akan balas 503. Isi dulu, contoh:
    echo     openssl rand -hex 32
    exit /b 1
)
echo   Rahasia Flask dimuat dari backend\.env (nilainya tidak ditampilkan).
start "Flask ML" cmd /k "cd /d "%ROOT%ML\api" && set ML_SHARED_SECRET=%ML_SECRET% && python app.py"

REM beri waktu startup sebelum health-check.
timeout /t 3 /nobreak >nul
curl -s http://127.0.0.1:5000/health 1>nul 2>nul && (echo   OK: Flask hidup) || (echo   WARN: /health Flask belum merespons, cek jendela "Flask ML")

echo.
echo [2/3] Menyalakan Laravel API (http://0.0.0.0:8000) ...
start "Laravel API" cmd /k "cd /d "%ROOT%smart_farming\backend" && php artisan serve --host=0.0.0.0 --port=8000"

timeout /t 3 /nobreak >nul
curl -s http://127.0.0.1:8000/api 1>nul 2>nul && (echo   OK: Laravel hidup) || (echo   WARN: cek jendela "Laravel API"; pastikan .env: FLASK_ML_BASE_URL=http://127.0.0.1:5000)

echo.
echo [3/3] Mode Flutter = %MODE%
if /I "%MODE%"=="none" (
    echo   Lewati langkah Flutter (backend saja).
    goto done
)

REM Deteksi IP LAN untuk ApiConfig.baseUrl perangkat fisik.
echo   Deteksi IP LAN untuk diakses perangkat (harus 1 Wi-Fi dgn laptop):
ipconfig | findstr /C:"IPv4"

if /I "%MODE%"=="flutter" (
    echo   Menjalankan flutter run (debug) pada perangkat terhubung...
    cd /d "%ROOT%smart_farming" && flutter run
) else if /I "%MODE%"=="apk" (
    echo   Install release APK ke perangkat terhubung...
    cd /d "%ROOT%smart_farming" && flutter install build\app\outputs\flutter-apk\app-release.apk
) else (
    echo   Mode tidak dikenal: %MODE%. Pakai: flutter ^| apk ^| none
)

:done
echo.
echo ========================================
echo  Layanan aktif di jendela terpisah.
echo  Tutup jendela tsb untuk menghentikan.
echo ========================================
endlocal
