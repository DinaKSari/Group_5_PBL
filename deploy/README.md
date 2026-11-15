# deploy/ — menyalakan laptop ini sebagai server LettuGrow

`run_all.bat` di root tetap untuk **development** (Flask + Laravel + `flutter run`, bind `0.0.0.0`).
Isi folder ini untuk **melayani user nyata**: MySQL dinyalakan kalau belum hidup, lalu Flask ML,
Laravel, dan tunnel ngrok — berurutan, dengan pemeriksaan yang gagal keras daripada diam-diam.

## Paling sering dipakai

| Mau apa | Jalankan |
|---|---|
| Nyalakan semuanya sampai dapat URL publik | `deploy\start_tunnel.bat` (klik dua kali) atau `.\start_tunnel.ps1` |
| Cuma lokal, tanpa internet/publik | `.\start_tunnel.ps1 -NoNgrok` |
| Lihat apa yang hidup + URL aktif | `.\start_tunnel.ps1 -Status` |
| Matikan Laravel + Flask + ngrok (MySQL tetap) | `.\start_tunnel.ps1 -Stop` |
| ... termasuk MySQL, tapi **rapi** (bukan kill paksa) | `.\start_tunnel.ps1 -Stop -MySql` |

Semua proses yang dinyalakan skrip dicatat PID-nya di `logs\pids\` dan log-nya di `logs\`.
Skrip ini **idempoten**: port yang sudah dipakai dilewati, jadi aman dijalankan ulang
di atas Laragon yang sudah jalan.

## Yang membuat skrip berhenti (dan alasannya)

- `FLASK_ML_SHARED_SECRET` kosong → Laravel balas 503 dan Flask menolak semua `/predict`.
- `APP_DEBUG` bukan `false` → satu error akan memancarkan stack trace + isi config ke HP user.
- Flask tidak bind dalam 60 detik → hampir selalu karena artefak `.joblib` tidak cocok dengan
  versi numpy/xgboost (`ML/api/requirements.txt` dipin ke versi yang benar).
- `/api/predict` membalas body yang mengandung `"exception"` → debug masih aktif, `php artisan config:clear`.

## Autostart setelah boot (butuh Administrator sekali)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\install-autostart.ps1
# uji tanpa reboot:
Start-ScheduledTask -TaskName 'LettuGrow Tunnel'
Get-Content deploy\logs\autostart.log -Tail 20
# bongkar:
powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\uninstall-autostart.ps1
```

Task berjalan sebagai **SYSTEM saat boot** (tanpa ada yang login) dan mengulang tiap 2 menit
kalau gagal. Karena SYSTEM tidak punya `%LOCALAPPDATA%` milik kalian, `install-autostart.ps1`
menulis path `ngrok.yml` kalian ke `deploy\tunnel.config.json` (file itu tidak masuk git).

**Status: terpasang & teruji 2026-11-16.** Proxy uji tanpa reboot: `-Stop` lalu
`Start-ScheduledTask` → Flask/Laravel/ngrok hidup lagi dalam ±12 detik (`logs\autostart.log`).

Konsekuensi yang harus diketahui sejak task ini aktif:
- Layanan bukan lagi milik terminal kalian (Session 0 / SYSTEM). `start_tunnel.ps1 -Stop` dari
  PowerShell biasa **gagal** (`taskkill ... could not be terminated`), dan penjaga akan
  menyalakan ulang dalam ≤60 detik. Yang benar: PowerShell *Run as administrator* →
  `Disable-ScheduledTask -TaskName 'LettuGrow Tunnel'` lalu `.\start_tunnel.ps1 -Stop`.
  Bongkar permanen: `uninstall-autostart.ps1` (elevated juga).
- Laptop ini menjadi server publik setiap kali menyala — termasuk saat kalian lupa
  menyalakannya untuk demo. `APP_DEBUG=false` dipaksa, Flask hanya bind `127.0.0.1`,
  dan seluruh endpoint API menolak request tanpa idToken.


## Kalau autofinder salah tebak

Salin `tunnel.config.example.json` → `tunnel.config.json`, lalu isi path absolut
(`php.exe`, `mysqld.exe`, `ngrok.exe`, `python.exe`, `ngrok.yml`). Kosong = pakai pencarian
otomatis (`where` lalu glob `C:\laragon\bin\...`).

## Kuota ngrok free

20.000 request/bulan dan 1 GB. Satu kali buka dashboard = 2 request, riwayat = 1.
Jangan pernah menambah polling `Timer` di aplikasi: satu device yang polling 5 detik
habis ±518.000 request/bulan dan langsung membunuh kuota semua orang. Pantau di
`dashboard.ngrok.com/usage` sekali seminggu.
