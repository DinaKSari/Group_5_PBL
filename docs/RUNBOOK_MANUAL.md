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
      keluar — pemulihan otomatis baru ada sejak item 7 di bawah terpasang (2026-11-16).
- [x] 7. **Autostart TerPASANG & teruji tanpa reboot (2026-11-16)** — task `LettuGrow Tunnel`
      terdaftar (SYSTEM, trigger `AtStartup`, restart 3× tiap 2 menit, tanpa batas waktu).
      Buktinya: rangkaian dimatikan (`-Stop`), lalu `Start-ScheduledTask` → dalam log
      `deploy\logs\autostart.log` tercatat `tunnel tidak aktif -> memanggil start_tunnel.ps1`
      dan 12 detik kemudian Flask 5000 + Laravel 8000 + ngrok 4040 hidup lagi dengan URL publik
      yang sama; `GET /up` dari internet = 200.
      ⚠️ Yang berubah untuk kalian: layanan sekarang jalan di **Session 0 milik SYSTEM**, jadi
      `.\start_tunnel.ps1 -Stop` dari terminal VS Code biasa **tidak bisa** matikan
      (`taskkill ... could not be terminated`). Cara berhenti yang benar:
      PowerShell *Run as administrator* → `Disable-ScheduledTask -TaskName 'LettuGrow Tunnel'`
      lalu `.\start_tunnel.ps1 -Stop`. Bongkar total: `uninstall-autostart.ps1` (juga elevated).
      ⚠️ Dan konsekuensi yang harus kalian sadari: sejak sekarang, **siapa pun yang menyalakan
      laptop ini ikut menyalakan server publik**. `APP_DEBUG=false` sudah paksa dan tidak ada
      data user terbaca tanpa idToken, tapi password admin Filament (R10) masih harus diganti.

  ```powershell
  # pasang (butuh UAC sekali):
  powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\install-autostart.ps1
  # cek / uji tanpa reboot (elevated):
  Get-ScheduledTask -TaskName 'LettuGrow Tunnel' | Format-List TaskName,State
  Start-ScheduledTask -TaskName 'LettuGrow Tunnel'
  Get-Content deploy\logs\autostart.log -Tail 20
  # bongkar:
  powershell -NoProfile -ExecutionPolicy Bypass -File deploy\windows-autostart\uninstall-autostart.ps1
  ```

  Kalau autofinder salah menebak path binaries, salin `deploy\tunnel.config.example.json`
  → `deploy\tunnel.config.json` lalu isi path-nya (file itu di-gitignore). Installer sudah
  menulis `ngrok.yml` kalian ke sana otomatis, karena SYSTEM tidak punya `%LOCALAPPDATA%`
  milik user — itu yang membuat ngrok tetap autentik walau task berjalan tanpa login.



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
**Memblokir: M3** · ±15 menit · ✅ **M3 TERBUKA 2026-11-16** — keystore jadi, `app-release.apk`
55,8 MB bertanda tangan `CN=LettuGrow` (apksigner); sisa = langkah 3 (cadangan di luar laptop)

Passphrase dibuat oleh kalian, bukan oleh saya — dan jangan sampai hanya saya yang memegangnya.
Skripnya sudah ada di repo; tidak perlu mengetik `keytool` manual.

- [x] 1. **Generate selesai 2026-11-16** (dari folder `smart_farming`):

  ```powershell
  powershell -ExecutionPolicy Bypass -File tool\make_keystore.ps1
  ```

  Hasil: `C:\Users\server\.android\letugrow-release.keystore` (PKCS12, RSA 2048), alias
  `letugrow`, `PrivateKeyEntry`, Owner `CN=LettuGrow, OU=Smart Farming, O=Kelompok 5, C=ID`,
  berlaku 16 Nov 2026 → **3 Apr 2054**.
  Fingerprint SHA-256 keystore:
  `12:67:ED:21:7E:16:F2:C1:2B:60:D1:BC:1B:F7:15:A8:4C:1F:97:3B:00:97:1F:7B:2E:5A:EE:00:5B:88:15:C4`
  Passphrase 20 karakter, diketik sendiri oleh pengelola lewat `Read-Host -AsSecureString` —
  tidak pernah tercetak, tidak pernah masuk argemen baris perintah, tidak pernah lewat chat.
  ⚠️ Bug yang ditemukan & diperbaiki (`929c9d1`): langkah pemeriksaan anti-bocor mati oleh
  stderr git (`ls-files --error-unmatch` menulis "did not match any file(s)" justru saat file
  **tidak** terlacak, dan `ErrorActionPreference='Stop'` menaikkan itu jadi error fatal).
  Efeknya hanya langkah konfirmasi + prompt cadangan yang tidak tampil — keystore &
  `key.properties` sudah terbentuk benar. Kalau skrip kalian menampilkan error yang sama,
  itu sudah diperbaiki di commit tersebut; jalankan ulang dengan `-Force` hanya kalau kalian
  **sudah** merelakan keystore lama (lihat langkah 3).
- [x] 2. **Terverifikasi 2026-11-16**: `smart_farming/android/key.properties` tertulis
      (`storeFile`, `storeType=PKCS12`, `keyAlias=letugrow`, `storePassword`, `keyPassword`) dan
      `git check-ignore -v` → `smart_farming/android/.gitignore:13:key.properties`;
      `git ls-files android/key.properties` kosong = tidak terlacak. Keystore ada di luar repo
      (`%USERPROFILE%\.android`), jadi tidak mungkin ikut ter-commit. `git status` bersih dari
      file rahasia. **Nilai passphrase tidak pernah dibaca/dicetak** — verifikasi memakai
      `keytool -storepass:env` dengan passphrase diambil dari file.
- [ ] 3. **SATU-SATUNYA YANG BELUM: salin `C:\Users\server\.android\letugrow-release.keystore`
      ke lokasi di luar laptop** (flashdisk / cloud pribadi). Prompt `Read-Host` yang biasanya
      menahan kalian di langkah ini tidak sempat tampil karena bug di langkah 1, jadi ini
      benar-benar harus kalian lakukan manual sekarang. Cocokkan fingerprint di atas dengan
      file salinan kalian. Tanpa salinan ini: laptop hilang/partisi/keystore korup = semua user
      uninstall + install ulang APK, dan riwayat di HP mereka tidak bisa disambung.
      Simpan passphrase di password manager kampus **terpisah** dari file keystore-nya.
- [x] 4. **Build APK rilis selesai 2026-11-16** (`tool\build_release.ps1`, exit 0):
      `smart_farming\build\app\outputs\flutter-apk\app-release.apk` — **55,8 MB**,
      Gradle `assembleRelease` 18,8 s (build penuh pertama 176,7 s). `version: 1.0.0+1` dari
      `pubspec.yaml` diteruskan sebagai `--dart-define=APP_VERSION=1.0.0`; `key.properties`
      terbaca sehingga `signingConfigs.release` dipakai, bukan fallback debug.
      Peringatan tak berbahaya: `firebase_auth`/`firebase_core`/`firebase_remote_config` masih
      memakai Kotlin Gradle Plugin lama (akan dihapus Flutter di masa depan), dan font asset
      ter-tree-shake (normal untuk rilis).
- [x] 5. **Bukti tanda tangan (apksigner, bukan keytool)**:

  ```powershell
  & "$env:LOCALAPPDATA\Android\Sdk\build-tools\36.0.0\apksigner.bat" verify --verbose --print-certs `
      build\app\outputs\flutter-apk\app-release.apk
  ```

  ```
  Verifies
  Verified using v2 scheme (APK Signature Scheme v2): true
  Signer #1 certificate DN: CN=LettuGrow, OU=Smart Farming, O=Kelompok 5, C=ID
  Signer #1 certificate SHA-256 digest: 1267ed217e16f2c12b60d1bc1bf715a84c1f973b00971f7b2e5aee005b8815c4
  Signer #1 key algorithm: RSA, key size 2048 bits
  ```

  SHA-256 signer **sama persis** dengan fingerprint keystore di langkah 1 → APK ini ditandatangani
  kunci kelompok, dan hanya ada 1 signer. ⚠️ `keytool -printcert -jarfile` TIDAK bisa dipakai untuk
  bukti ini: APK Flutter ditandatangani scheme v2 tanpa v1/JAR, jadi keytool membalas
  "Not a signed jar file" dengan exit 0. Checks itu pernah menghasilkan `[OK]` palsu dan sudah
  diganti apksigner di `tool\build_release.ps1`.
- [x] 6. Path + alias sudah di tangan saya dan tercatat di atas: keystore
      `%USERPROFILE%\.android\letugrow-release.keystore`, alias `letugrow`. Passphrase tidak
      pernah dikirim ke chat.

Konsekuensi yang perlu kalian ingat: `applicationId` sekarang `com.lettgrow.app` dan APK lama
ber-package `com.kelompok5.smart_farming` adalah app berbeda, sedangkan APK debug dengan package
sama tidak bisa ditimpa oleh APK rilis (tanda tangan beda → `INSTALL_FAILED_UPDATE_INCOMPATIBLE`).
Sebelum install ke HP: `adb uninstall com.lettgrow.app` dulu.



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
| 1 | 4G asli | Matikan Wi-Fi HP, install APK, login → prediksi | hasil muncul ≤ 10 detik | **TIDAK BISA DI HP UJI** — `EQFUD64HBIZDQKTW` tanpa SIM (`gsm.sim.state=ABSENT,ABSENT`); perlu HP lain ber-SIM. Semua request hari ini lewat Wi-Fi "Kos Rahman" ke URL publik yang sama |
| 2 | Server mati | Close ngrok + `artisan serve`, lalu buka app | ada teks "server offline", **bukan** layar kosong | `[ ]` |
| 3 | **Reboot laptop** | Restart Windows, **jangan sentuh apa pun** selama 3 menit | app berfungsi lagi tanpa perintah manual | `[ ]` |
| 4 | Lintas user | Akun B login di HP lain, coba buka riwayat A | ditolak 403 | `[ ]` |
| 5 | Session kedaluwarsa | Diamkan app > 1 jam, lalu tarik data | auto-refresh atau logout, tidak hang | `[ ]` |
| 6 | Hapus akun | Jalankan jalur hapus akun, cek MySQL | baris data user hilang | **FITURNYA BELUM ADA** — tidak ada route penghapusan di `backend/routes/api.php` dan tidak ada tombolnya di app; bukan kegagalan tes, tapi keputusan scope yang harus diambil (buat jalur hapus, atau tulis "data dihapus manual oleh admin" di laporan) |
| 7 | Bersamaan | 3 HP menekan tombol prediksi barengan | tidak ada timeout/antre > 15 detik | `[ ]` |
| 8 | **Entri manual (P4)** | Home → tile "Catat Parameter Kebun", isi 5 nilai di luar rentang dulu (mis. pH 12) | ditolak dengan teks "pH harus di antara 4 dan 9"; nilai valid tersimpan dan dashboard langsung menampilkannya | `[ ]` |
| 9 | Entri manual saat mode tamu | Login sebagai Tamu, coba buka `/sensor-entry` | tidak bisa masuk / muncul "Masuk untuk mencatat parameter kebun kalian." | **LULUS** (setelah bug) — tadinya tombol Tamu terpental balik ke splash: guard router memeriksa `Session.hasAccount` yang justru `false` untuk tamu. Diperbaiki `9cec9ac`, kini Home tamu tampil read-only dan tile mencatat menolak dengan pesan yang benar (terscreenshot) |
| 10 | Peringatan versi | Setel `minimum_supported_version` Remote Config di atas versi APK, buka app | banner non-dismissible muncul di Home, app **tetap** bisa dipakai | `[ ]` |
| 11 | Remote Config sampai | Publish `api_base_url`, restart app (butuh R4) | data monitoring datang dari URL itu; ubah URL → app ikut tanpa build ulang | `[ ]` |
| 12 | APK rilis = HTTPS saja | Pasang `app-release.apk`, matikan `adb reverse` | login/prediksi jalan lewat ngrok; tidak ada kegagalan cleartext HTTP | **LULUS statis** — manifest rilis APK terpasang: 0 `usesCleartextTraffic`, 0 `debuggable` (`aapt dump xmltree`); `POST /api/devices` dari HP hari ini sukses lewat HTTPS. Sisa: satu login/prediksi manual saat memakai data seluler (lihat #1) |
| 13 | Nama app | Lihat launcher + *Tentang* | tertulis **LettuGrow** (`applicationId` `com.lettgrow.app`) | **LULUS** — `aapt dump badging` APK terpasang: `application-label:'LettuGrow'`, versionName 1.0.0 |
| 14 | Ganti akun tanpa tutup app | Login akun A → Riwayat → logout → login akun B → langsung buka Riwayat | daftar milik A **hilang** dan tergantikan milik B (tanpa force-stop) | `[ ]` |

Catatan tes #3: **proxy-nya sudah dijalankan 2026-11-16 dan lulus** — task autostart aktif,
rangkaian dimatikan lalu `Start-ScheduledTask` menyalakan semuanya kembali dalam 12 detik
(`deploy\logs\autostart.log`). Yang tersisa di baris ini hanya pembuktiannya saat laptop memang
perlu dinyalakan ulang: me-restart laptop demi tes akan mematikan sesi kerja kalian, jadi itu
keputusan manusia, bukan tugas saya.

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
- [x] Menghentikan proses yang sedang berjalan (php / mysql / redis / ngrok) — sejak ada
      `deploy\start_tunnel.ps1` ini tidak lagi saya lakukan sendiri; kalian yang menjalankan
      `-Stop` / `-Stop -MySql`, dan **tidak ada** `taskkill` liar (PID dicatat di
      `deploy\logs\pids\`, MySQL dihentikan rapi). Yang sudah terjadi hanya menghentikan web
      server probe milik saya sendiri.
- [x] **Mendaftarkan task Scheduler tingkat SYSTEM yang menyala saat boot** (2026-11-16, atas
      permintaan kalian: `install-autostart.ps1` + `Start-ScheduledTask` + `-Stop` untuk uji).
      Ini mengubah mesin di luar repo: dua kali prompt UAC kalian accept, layanan kini di-start
      sebagai SYSTEM di Session 0, dan laptop otomatis jadi server publik setiap kali menyala.
      Bongkar: `uninstall-autostart.ps1` (elevated). Satu bug nyata ikut ditemukan & diperbaiki:
      `New-ScheduledTaskAction -Argument` di mesin ini menolak array, jadi rangkaian argumen
      sekarang satu string (`deploy/windows-autostart/install-autostart.ps1:79`).

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
