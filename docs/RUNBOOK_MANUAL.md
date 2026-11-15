# RUNBOOK MANUAL — langkah yang hanya bisa dikerjakan manusia

Bagian dari plan publikasi Smart Farming Kelompok 5. File ini berisi **hanya** pekerjaan
yang tidak bisa saya (agent) selesaikan sendiri: keputusan produk, login browser, pegang
kredensial, dan pengujian empiris di perangkat nyata.

Format centang: `[ ]` belum, `[x]` selesai. Kalau satu item gagal/tertunda, tulis alasannya
di baris berikutnya supaya ada jejak untuk laporan & RTM.

Status milestone yang terblokir tertulis di judul tiap bagian.

---

## R1 — Tetapkan identitas app
**Memblokir: M3 (build release), M0 (dokumen)** · ±5 menit

Keputusan, bukan perintah terminal. Kirim jawabannya dalam satu pesan:

- [x] **Nama app** = **LettuGrow** (keputusan 2026-11-16; ✅ diterapkan 2026-11-16 `79eb092`:
      `android:label="LettuGrow"` di `AndroidManifest.xml`, `web/index.html` + `web/manifest.json`
      dan `description:` `pubspec.yaml` ikut. `pubspec name:` sengaja tetap `smart_farming` —
      mengubahnya menyentuh ±40 import demi kosmetik).
- [x] **`applicationId` final = (B) `com.lettgrow.app`** (keputusan + dieksekusi 2026-11-16:
      Android app baru sudah didaftarkan di Console Firebase dan
      `smart_farming/android/app/google-services.json` sudah ditimpa — terverifikasi berisi
      2 client: `com.kelompok5.smart_farming` dan `com.lettgrow.app`).
      ⚠️ Konsekuensi yang sudah kalian terima: APK lama dengan package `com.kelompok5.smart_farming`
      adalah **app berbeda** — install ulang, bukan update.
      Kerja saya (`79eb092`): `applicationId` di `build.gradle.kts` diganti, **`namespace`
      sengaja TIDAK diubah** — memindahkan `MainActivity.kt` tanpa bisa menguji build di HP
      adalah risiko murni. Sudah terbukti di laptop ini: `gradlew :app:processReleaseManifest`
      + `:app:processReleaseGoogleServices` BUILD SUCCESSFUL dan paket Firebase-nya cocok.
- [x] **Mode Tamu = read-only** (keputusan 2026-11-16) — ✅ **dieksekusi 2026-11-16 (M1.4/M1.5)**:
      `Session.isGuest` dipasang oleh tombol "Masuk Langsung sebagai Tamu" (`splash_page.dart`);
      router guard (`lib/routes.dart`) kini menolak `/home|/prediksi|/riwayat` tanpa akun
      Firebase, jadi tamuan tidak lagi punya "identitas kosong" yang bisa dipakai ke API.
      Layer data menahan diri: riwayat & dashboard tidak memanggil jaringan, form prediksi
      membalas `AuthFailure` + tombol **Masuk** di snackbar
      (`test/api_auth_contract_test.dart` membuktinya). Sisa kerja kalian untuk item ini:
      **tidak ada** — hanya pastikan keputusan ini cocok dengan kalimat di bab UX laporan.
- [x] **Sumber data sensor = (P4) halaman entri manual** (keputusan 2026-11-16, ✅ dieksekusi
      `5971303`) — menggantikan (a): "device menabung & retry" tidak punya device, karena kalian
      mengonfirmasi **tidak ada sumber data sensor** (tanpa firmware ESP32, tanpa skrip pengirim).
      Yang dibangun: tile **Catat Parameter Kebun** di Home → layar `/sensor-entry` →
      `POST /api/sensor` dengan `source: 'manual'`. Rentang input dibangun dari
      `kGrowthParameters` sehingga **identik** dengan validasi `SensorController::store()`
      (umur 1–45, suhu 10–40, kelembapan 30–100, TDS 200–1500, pH 4–9); tidak ada endpoint baru,
      tidak ada scheduler, 1 request per simpan, dan dashboard langsung menampilkan angka baru.
      Mode tamu tetap read-only (`AuthFailure`, bukan senyap).
      Kalimat siap pakai untuk bab IoT laporan ada di `docs/PLAN.md` §4A — pakai apa adanya,
      jangan diubah menjadi "berbasis sensor".
- [ ] **Buffer sensor = (a) device menabung & retry** — jadi **opsi masa depan**, bukan tugas
      tertunda: baru punya tempat setelah ada perangkat keras (P1 firmware nyata atau P2 skrip
      pengirim). Kalau nanti ESP32 benar-benar ada, `POST /api/sensor` sudah siap menerimanya.

> Item sensor saya tidak pilihkan sebelumnya karena dampaknya ke klaim di laporan, bukan ke
> teknis — dan karena itu keputusan (P4) kalian ambil sendiri. Konsekuensi yang harus diterima
> di laporan: modul monitoring adalah **buku catatan**, bukan telemetri.

---

## R2 — Akun ngrok + static domain
**Memblokir: M2** · ±10 menit · Rp 0, tanpa kartu

- [x] 1. Daftar di `https://dashboard.ngrok.com/signup` (email saja).
- [x] 2. Authtoken tersimpan (2026-11-16) di `C:\Users\server\AppData\Local\ngrok\ngrok.yml`;
      **tidak ada file kredensial yang ditulis ke repo.** ⚠️ Token sempat dikirim lewat chat →
      regenerate di dashboard setelah M2 stabil.
- [x] 3. ~~Create Domain~~ **TIDAK PERLU dan memang BERBAYAR.** Yang kalian lihat di dashboard
      adalah *Reserved static domain* (fitur paid plan). Free plan menyediakan **dev domain yang
      otomatis ter-assign ke akun dan tidak berubah saat restart agent**.
      Dev domain akun kalian (dibaca 2026-11-16 lewat probe singkat):
      **`https://craftily-handcraft-outboard.ngrok-free.dev`**
      → `ngrok http 8000` memakainya otomatis, tanpa klik apa pun.
- [x] 4. ⚠️ Perbaikan lingkungan: agent bawaan Laragon `ngrok 3.1.0` **ditolak server**
      (`ERR_NGROK_121`, minimal agent 3.29.0). Sudah `ngrok update` → **3.39.13**.
      Kalau suatu hari muncul ERR_NGROK_121 lagi, jalankan `ngrok update`.
- [ ] 5. Verifikasi sendiri di dashboard: halaman *Domains* harus menampilkan dev domain di atas.
      (Sudah terbukti dari sisi teknis 2026-11-16: agent akun ini benar-benar melayani
      `https://craftily-handcraft-outboard.ngrok-free.dev`, jadi domain itu memang ter-assign —
      centang setelah kalian melihatnya sendiri di browser.)
- [x] 6. **Dijalankan & terverifikasi 2026-11-16** lewat `.\deploy\start_tunnel.ps1`:
      MySQL (3306) → Flask ML (5000) → Laravel (8000) → ngrok (4040) hidup, dan dari internet
      terbukti: `GET /up` = 200 dalam 0,6 s tanpa interstitial, `GET /api/sensor/latest` tanpa
      token = 401 JSON, dengan token sampah = 401 JSON, `POST /api/predict` tanpa token = 401 JSON
      (tidak ada `exception`/`file`/`trace` yang keluar). URL tersimpan di `deploy\last-url.txt`.
      Skripnya sendiri: `deploy\start_tunnel.bat` (klik dua kali) atau
      `.\deploy\start_tunnel.ps1`; `-Status` melihat tanpa mengubah apa pun, `-Stop` matikan
      Laravel/Flask/ngrok (MySQL dibiarkan), `-NoNgrok` lokal saja.
      ⚠️ Ini status **sekarang**, bukan permanen: tunnel mati begitu laptop mati atau ngrok
      keluar, dan `deploy\windows-autostart\install-autostart.ps1` **belum** kalian
      jalankan (butuh UAC), jadi belum ada jaminan pulih sendiri setelah boot.
- [ ] 7. Autostart setelah boot (butuh Administrator sekali — tidak bisa saya kerjakan):

  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\install-autostart.ps1
  # uji TANPA reboot (ini yang menggantikan keberanian menyalakan ulang laptop):
  Start-ScheduledTask -TaskName 'LettuGrow Tunnel'
  Get-Content deploy\logs\autostart.log -Tail 20
  # bongkar:
  powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\uninstall-autostart.ps1
  ```

  Detail & alasan tiap langkah ada di `deploy\README.md`. Kalau autofinder salah menebak path
  binaries, salin `deploy\tunnel.config.example.json` → `deploy\tunnel.config.json` lalu isi
  path-nya (file itu di-gitignore).


**Kuota free plan yang membatasi jumlah user** (dari dokumen resmi ngrok, 2026-11-16):
20.000 request HTTP/bulan, 1 GB data keluar/bulan, maks 3 endpoint online. Dengan 2 request per
refresh dashboard hari ini, plafonnya ±10.000 refresh/bulan (≈330/hari). Konsekuensi teknis ada
di PLAN §7 (endpoint agregat + larangan auto-poll).

---

## R3 — Service account Firebase → Laravel
**Memblokir: M1.1** · ±10 menit · ✅ **SELESAI & dipakai M1.1 (2026-11-16)**

- [x] 1. Console Firebase → *Project settings* → *Service accounts* → **Generate new private key**.
- [x] 2. Simpan JSON di server lokal — **jangan di chat, jangan di repo**:

  ```sh
  mkdir -p "D:/KULIAH/SMT-5/PBL - Project Base Learning/Group_5_PBL/smart_farming/backend/storage/app/private"
  # pindahkan file JSON hasil download ke folder tsb dengan nama: firebase-service-account.json
  ```

- [x] 3. Pastikan tidak akan ter-commit:

  ```sh
  cd "D:/KULIAH/SMT-5/PBL - Project Base Learning/Group_5_PBL"
  git check-ignore -v smart_farming/backend/storage/app/private/<nama-file-json-kalian>
  ```

  Sudah diverifikasi aktif: `smart_farming/backend/storage/app/private/.gitignore:1` berisi `*`,
  jadi seluruh isi folder itu tidak akan pernah ter-commit. Aman langsung menaruh file-nya.
- [x] 4. **Diterima & diverifikasi**: file `smart-farming-683ec-firebase-adminsdk-fbsvc-98872aec17.json`
      (project `smart-farming-683ec`, sama dengan project di `google-services.json` HP kalian).
      Nilai env `FIREBASE_CREDENTIALS` + `FIREBASE_PROJECT_ID` sudah ditulis ke
      `backend/.env` (di-gitignore) dan `.env.example` sebagai placeholder kosong.

---

## R4 — Remote Config
**Memblokir: pindah host tanpa build ulang APK** · ±5 menit, butuh R3 · kode Flutter-nya **sudah selesai** (`7f4e33b`)

Yang sudah ada di repo dan tidak perlu kalian sentuh: `firebase_remote_config ^7.0.1` di
`smart_farming/pubspec.yaml`, pembaca nilainya di `smart_farming/lib/core/remote_settings.dart`
(dipanggil sekali di `lib/main.dart` sesudah `Firebase.initializeApp`, timeout 3 detik, gagal =
diam dan pakai default build), dan prioritas di `lib/config/api_config.dart`:
**`--dart-define=API_BASE_URL` → Remote Config → default build** (`http://127.0.0.1:8000/api`
untuk debug, dev domain ngrok untuk rilis).

- [ ] 1. Console Firebase → project **smart-farming-683ec** → *Build* → *Remote Config* →
      **Get started** (gratis, tanpa kartu).
- [ ] 2. *Add parameter*, dua-duanya tipe **String**, nama persis seperti ini (kode mencocokkan
      string-nya, bukan yang lain):
  - [ ] `api_base_url` = `https://craftily-handcraft-outboard.ngrok-free.dev/api`
  - [ ] `minimum_supported_version` = `1.0.0`
- [ ] 3. **Publish changes** — Remote Config tidak mengirim apa pun selama hanya di-save sebagai draft.
- [ ] 4. Konfirmasi kedua nama itu sudah ada di daftar published. Tidak perlu mengirim nilai/token.

Kalau R4 ditunda, **tidak ada yang macet**: `tool\build_release.ps1` sudah menyalakan mode rilis
sehingga default build-nya dev domain ngrok (`ApiConfig.releaseDefault`), jadi APK tetap bisa
dipakai; opsi `-ApiBaseUrl <url>` tersedia kalau ingin memaksanya. Remote Config baru dibutuhkan
saat nanti pindah hosting (Oracle Free + DuckDNS) dan kalian tidak ingin membangun APK dari nol.

Verifikasi di HP (masuk R7): setelah publish, buka app → tarik-bawah Home → angka di tile
"Monitoring" mengikuti backend yang ditunjuk `api_base_url`. Nilai yang sumbernya Remote Config
tidak akan menimpa `--dart-define` yang di-set saat build; itu memang disengaja supaya debugging
di LAN tetap bisa dipaksa kembali ke laptop.

---

## R5 — Keystore release
**Memblokir: M3** · ±15 menit · **jangan lanjut tanpa backup**

Passphrase dibuat oleh kalian, bukan oleh saya — dan jangan sampai hanya saya yang memegangnya.
Skripnya sudah ada di repo; tidak perlu mengetik `keytool` manual.

- [ ] 1. Generate (dari folder `smart_farming`):

  ```powershell
  powershell -ExecutionPolicy Bypass -File tool\make_keystore.ps1
  ```

  Ditanya: folder tujuan (default `%USERPROFILE%\.android`), nama file
  (`letugrow-release.keystore`), alias (default `letugrow`), lalu passphrase **2×** lewat
  `Read-Host -AsSecureString`. Passphrase tidak pernah tercetak, tidak masuk argemen baris
  perintah (dioper ke `keytool` via environment proses anak), dan tidak perlu dikirim ke chat.
  Sudah diverifikasi syntax-nya di PowerShell 5.1 dan menolak jalan kalau keystore lama akan
  tertimpa tanpa `-Force`.
- [ ] 2. Skrip otomatis menulis `smart_farming/android/key.properties` dan menjalankan
      `git check-ignore -v` untuk file itu (dan untuk keystore kalau di dalam repo) — **berhenti
      dengan error** kalau ada yang terlacak git. Aturan `.gitignore`-nya sudah terverifikasi aktif
      (`smart_farming/android/.gitignore:13` = `key.properties`, `:14` = `**/*.keystore`).
- [ ] 3. **Salin file `.keystore` ke satu lokasi di luar laptop** (flashdisk / cloud pribadi).
      Skrip menampilkan jalurnya dan menahan diri di prompt `Read-Host` sampai kalian menekan
      ENTER setelah menyalinnya. Tanpa langkah ini: laptop hilang/partisi = semua user
      uninstall + install ulang APK.
- [ ] 4. Build APK rilis:

  ```powershell
  powershell -ExecutionPolicy Bypass -File tool\build_release.ps1
  ```

  Membaca `version:` dari `pubspec.yaml` → `--dart-define=APP_VERSION=...` (pembanding
  `minimum_supported_version` Remote Config), output
  `smart_farming\build\app\outputs\flutter-apk\app-release.apk`.
  `android/app/build.gradle.kts` memakai `key.properties` kalau ada, dan jatuh kembali ke
  signing debug kalau tidak — jadi build hari ini tidak pernah rusak karena langkah ini.
- [ ] 5. Bukti sertifikat release (saya yang jalankan, kalian boleh ulangi):

  ```powershell
  & "$env:JAVA_HOME\bin\keytool.exe" -printcert -jarfile build\app\outputs\flutter-apk\app-release.apk
  ```

  Harus muncul `CN=LettuGrow, OU=Smart Farming, O=Kelompok 5, C=ID`. Kalau yang muncul
  `CN=Android Debug`, `key.properties` tidak terbaca.
- [ ] 6. Kirim ke saya: **path keystore + alias**, dan konfirmasi langkah 2 tidak menemukan
      file rahasia yang terlacak git. **Jangan kirim passphrase** — saya baca dari file saat build.


---

## R6 — Monitor uptime + backup
**Memblokir: M2.5** · ±5 menit

- [ ] 1. Daftar UptimeRobot (free) → *HTTPS monitor* ke
      `https://craftily-handcraft-outboard.ngrok-free.dev/up`, notifikasi email ke ≥2 anggota
      kelompok. **Pilih interval 15 menit, bukan 5 menit** — monitor ini memakan kuota ngrok
      yang sama dengan user kalian: 5 menit = 288 request/hari ≈ 8.600/bulan (43% jatah
      20.000), 15 menit = ±2.880/bulan dan tetap menangkap laptop yang mati.
      (`/up` sudah tersedia sebagai health route — lihat `smart_farming/backend/bootstrap/app.php:13`;
      URL aktif juga selalu dicetak `.\deploy\start_tunnel.ps1 -Status`)
- [ ] 2. Kabari saya dashboard-nya aktif (atau kirim URL-nya).
- [ ] 3. Tentukan folder tujuan backup harian (di luar laptop). Job `mysqldump` + rotasinya
      **belum saya tulis** karena lokasinya memang keputusan kalian (item plan 2.5.7) —
      kabari foldernya, saya yang tulis skrip + task-nya (±30 menit, dan bisa sekalian
      digabung ke `deploy\windows-autostart`).
      Yang sudah ada dan sudah teruji: `smart_farming/backend/storage/app/private/backup-mysql-2026-11-16.sql`
      (42 KB, 75 baris data kelas) + salinan SQLite sebelum migrasi di folder yang sama. Folder itu
      di-gitignore, jadi **tugasmu hanya menyalinnya ke luar laptop**. Restore kalau perlu:
      `mysql -u root smart_farming < nama-file.sql`.
      ⚠️ Backup harian belum menjadi job terjadwal — dan laptop kalian memang mati setiap hari,
      jadi jendela kehilangan data = sejak backup terakhir sampai laptop dimatikan. Percepat
      item ini setelah ada user nyata.

---

## R7 — Uji empiris di perangkat nyata
**Memblokir: sign-off akhir publikasi** · ±30 menit

Laporkan hasilnya apa adanya. Kalau gagal, tulis "GAGAL + gejala" — itu lebih berharga daripada lulus palsu.

| # | Tes | Cara | Lulus kalau | Hasil |
|---|---|---|---|---|
| 1 | 4G asli | Matikan Wi-Fi HP, install APK, login → prediksi | hasil muncul ≤ 10 detik | `[ ]` |
| 2 | Server mati | Close ngrok + `artisan serve`, lalu buka app | ada teks "server offline", **bukan** layar kosong | `[ ]` |
| 3 | **Reboot laptop** | Restart Windows, **jangan sentuh apa pun** selama 3 menit | app berfungsi lagi tanpa perintah manual | `[ ]` |
| 4 | Lintas user | Akun B login di HP lain, coba buka riwayat A | ditolak 403 | `[ ]` |
| 5 | Session kedaluwarsa | Diamkan app > 1 jam, lalu tarik data | auto-refresh atau logout, tidak hang | `[ ]` |
| 6 | Hapus akun | Jalankan jalur hapus akun, cek MySQL | baris data user hilang | `[ ]` |
| 7 | Bersamaan | 3 HP menekan tombol prediksi barengan | tidak ada timeout/antre > 15 detik | `[ ]` |
| 8 | **Entri manual (P4)** | Home → tile "Catat Parameter Kebun", isi 5 nilai di luar rentang dulu (mis. pH 12) | ditolak dengan teks "pH harus di antara 4 dan 9"; nilai valid tersimpan dan dashboard langsung menampilkannya | `[ ]` |
| 9 | Entri manual saat mode tamu | Login sebagai Tamu, coba buka `/sensor-entry` | tidak bisa masuk / muncul "Masuk untuk mencatat parameter kebun kalian." | `[ ]` |
| 10 | Peringatan versi | Setel `minimum_supported_version` Remote Config di atas versi APK, buka app | banner non-dismissible muncul di Home, app **tetap** bisa dipakai | `[ ]` |
| 11 | Remote Config sampai | Publish `api_base_url`, restart app (butuh R4) | data monitoring datang dari URL itu; ubah URL → app ikut tanpa build ulang | `[ ]` |
| 12 | APK rilis = HTTPS saja | Pasang `app-release.apk`, matikan `adb reverse` | login/prediksi jalan lewat ngrok; tidak ada kegagalan cleartext HTTP | `[ ]` |
| 13 | Nama app | Lihat launcher + *Tentang* | tertulis **LettuGrow** (`applicationId` `com.lettgrow.app`) | `[ ]` |

Catatan: tes #3 sengaja tidak saya eksekusi — me-restart laptop mematikan sesi kerja kita dan
menguji autostart dengan cara itu berisiko pada pekerjaan kalian yang belum ter-commit.
Sejak `e44db28` jalur itu sudah ada `deploy\windows-autostart\install-autostart.ps1`, jadi #3 bisa
diproksikan **tanpa reboot**: `Start-ScheduledTask -TaskName 'LettuGrow Tunnel'` lalu cek
`deploy\logs\autostart.log` — urutan MySQL → Flask → Laravel → ngrok harus muncul. Baru setelah itu
#3 diuji sungguhan saat laptop memang perlu dinyalakan ulang.

---

## R8 — Persetujuan yang harus diucapkan sebelum saya jalan
Saya tidak melakukan ini tanpa kalian bilang ya, karena tidak aman dibatalkan:

- [x] `git commit` / `git push` — **sudah dipakai untuk commit saja** (16 commit di branch lokal,
      termasuk 5 commit M2/M3 terakhir yang terdaftar di `docs/PLAN.md` §19).
      **`git push` tidak pernah dijalankan dan tidak
      akan saya jalankan tanpa izin baru**; pekerjaan ada di branch lokal
      `feature-letugrow-m1-keamanan-mysql` (lihat §18–§19 `docs/PLAN.md`).
- [x] `git rm --cached` untuk `smart_farming/android/build/reports/**`, dan penghapusan
      `smart_farming/backend/AGENTS.md` + `CLAUDE.md` (M0) — selesai `bf94ac0`.
- [x] `composer require kreait/firebase-php` — selesai (M1.1).
- [x] Menjalankan migrasi MySQL yang mengubah data di DB lokal — selesai 2026-11-16
      (`php artisan migrate --force` + `tool/migrate_sqlite_to_mysql.php --apply`).
      `mysqldump` dan salinan SQLite-nya diambil **sebelum** menulis apa pun.
- [ ] Menghentikan proses yang sedang berjalan (php / mysql / redis / ngrok) — sejak ada
      `deploy\start_tunnel.ps1` ini tidak lagi saya lakukan sendiri; kalian yang menjalankan
      `-Stop` / `-Stop -MySql`, dan **tidak ada** `taskkill` liar (PID dicatat di
      `deploy\logs\pids\`, MySQL dihentikan rapi). Yang sudah terjadi hanya menghentikan web
      server probe milik saya sendiri.
- [ ] Mendaftarkan task autostart tingkat sistem (`install-autostart.ps1` → prompt UAC) —
      hak Administrator milik kalian, dan task yang berjalan sebagai SYSTEM menyentuh mesin
      di luar repo. Bongkar-pasangnya lewat `uninstall-autostart.ps1`.
- [ ] Menulis file baru ke repo: `LICENSE`, `CHANGELOG.md`, `PRIVACY_POLICY.md`,
      `docs/DEPLOYMENT.md`, `docs/USER_MANUAL.md`. (`docs/PLAN.md` & runbook ini sudah ada.)

---

## R9 — Opsional (tidak memblokir apa pun)
Kalau nanti ingin lepas dari "laptop = server":

- [ ] Daftar Oracle Cloud Always Free di `signup.oraclecloud.com`.
      Butuh **kartu debit/kredit fisik** hanya untuk verifikasi identitas — kartu virtual dan
      prepaid ditolak. Tidak ada tagihan selama di dalam batas Always Free
      (sejak 15 Juni 2026: 2 OCPU ARM + 12 GB RAM + 200 GB storage).
      Kalau tidak ada kartu: abaikan, plan ini tetap utuh tanpa itu.
- Upgrade ini memakai DuckDNS (gratis) + Let's Encrypt (gratis), **tetap tanpa membeli domain**.
      Prosedurnya dicatat sebagai lampiran di `docs/DEPLOYMENT.md`.

---
## R10 — Setel ulang rahasia & kredensial yang sempat bocor
**Tidak memblokir milestone, tapi jangan di-lupakan** · ±10 menit

Keputusan kalian sudah saya catat; yang hanya bisa kalian lakukan:

- [ ] **Regenerate ngrok authtoken** — token lama terkirim lewat chat (RUNBOOK R2 item 2).
      Dashboard ngrok → *Your Authtoken* → regenerate → `ngrok config add-authtoken <baru>`.
- [ ] **Ganti password admin Filament** yang sekarang ada di `backend/.env`
      (`ADMIN_EMAIL=admin@letugrow.local`, `ADMIN_PASSWORD` saya generate acak 24 karakter).
      Ganti dengan passphrase kalian sendiri sebelum ada yang memakai akun itu, simpan di
      password manager kampus, lalu terapkan:
      `php artisan db:seed --class=DatabaseSeeder --force` (seeder memakai `updateOrCreate`,
      jadi akun yang sudah ada ikut ter-update; menolak jalan jika `ADMIN_PASSWORD` < 12 karakter).
      Password tidak pernah masuk repo.
- [ ] Rotasi `FLASK_ML_SHARED_SECRET` setelah APK beredar. Cara aman agar kedua sisi berubah
      bersamaan — secret hanya dibaca dari **satu** tempat, `smart_farming/backend/.env`:
      1. `.\deploy\start_tunnel.ps1 -Stop -MySql` (menghentikan Laravel/Flask/ngrok dengan rapi).
      2. Ganti nilai `FLASK_ML_SHARED_SECRET` di `smart_farming/backend/.env`.
      3. `php artisan config:clear` — tanpa ini Laravel masih memakai nilai lama dari cache config.
      4. `deploy\start_tunnel.bat` — Flask di-start skrip itu dari env yang sama, jadi sisi Flask
         ikut berubah tanpa file kedua yang harus diedit.
      5. Verifikasi: `curl` ke `/api/predict` lewat URL ngrok (header `ngrok-skip-browser-warning`);
         balasannya 200, bukan 503. Ganti satu sisi saja = semua prediksi balas 503.
- [ ] Konfirmasi: tidak ada file service account / `.env` / `key.properties` yang ikut
      `git add`. Cek cepat: `git status --short | grep -E "\.env|service-account|key.properties"`
      harus kosong.


## Urutan paling efisien
Status 2026-11-16, sesudah 5 commit M2/M3: **R1 dan R3 selesai**, kode untuk Remote Config,
entri sensor, naskah tunnel, keystore dan signing **sudah ada dan terverifikasi di laptop**.
Yang tersisa hanyalah klik/login/pegang-kredensial/pengujian fisik, dan urutannya sekarang:

1. **R5** (`tool\make_keystore.ps1` + backup keystore) → tanpa ini tidak ada APK rilis yang
   bisa di-install user. Ini bottleneck sebenarnya.
2. **R2 item 6** (`deploy\start_tunnel.bat`) → server laptop jadi bisa dijangkau HP mana pun.
   Sekalian `install-autostart.ps1` (butuh UAC) supaya tidak ada yang mati saat laptop nyala ulang.
3. **R4** (2 parameter Remote Config + **Publish**) → opsional hari ini, wajib sebelum pindah
   hosting. Namanya harus persis; tidak ada nilai rahasia yang perlu dikirim ke saya.
4. **R6** (UptimeRobot 15 menit + folder backup) → menutup M2.5.
5. **R7** (13 tes di perangkat) → hasilnya masuk RTM; tanda tangan publikasi tidak berlaku
   sebelum tabel ini terisi apa adanya.
6. **R10** → kapan saja, tapi **sebelum APK beredar** (authtoken ngrok sempat lewat chat).
