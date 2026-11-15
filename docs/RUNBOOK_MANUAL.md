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

- [x] **Nama app** = **LettuGrow** (keputusan 2026-11-16; label di launcher masih
      `smart_farming` → diganti di M3, `AndroidManifest.xml:6`).
- [x] **`applicationId` final = (B) `com.lettgrow.app`** (keputusan + dieksekusi 2026-11-16:
      Android app baru sudah didaftarkan di Console Firebase dan
      `smart_farming/android/app/google-services.json` sudah ditimpa — terverifikasi berisi
      2 client: `com.kelompok5.smart_farming` dan `com.lettgrow.app`).
      ⚠️ Konsekuensi yang sudah kalian terima: APK lama dengan package `com.kelompok5.smart_farming`
      adalah **app berbeda** — install ulang, bukan update.
      Kerja saya di M3: `applicationId` (`build.gradle.kts:21`) + samakan `namespace` (`:9`)
      dengan package `MainActivity.kt`.
- [x] **Mode Tamu = read-only** (keputusan 2026-11-16) — ✅ **dieksekusi 2026-11-16 (M1.4/M1.5)**:
      `Session.isGuest` dipasang oleh tombol "Masuk Langsung sebagai Tamu" (`splash_page.dart`);
      router guard (`lib/routes.dart`) kini menolak `/home|/prediksi|/riwayat` tanpa akun
      Firebase, jadi tamuan tidak lagi punya "identitas kosong" yang bisa dipakai ke API.
      Layer data menahan diri: riwayat & dashboard tidak memanggil jaringan, form prediksi
      membalas `AuthFailure` + tombol **Masuk** di snackbar
      (`test/api_auth_contract_test.dart` membuktinya). Sisa kerja kalian untuk item ini:
      **tidak ada** — hanya pastikan keputusan ini cocok dengan kalimat di bab UX laporan.
- [ ] **Buffer sensor = (a) device menabung & retry** (keputusan 2026-11-16) — **masih tertunda**,
      tapi alasannya sekarang lebih presisi (PLAN §4A sudah dikoreksi 2026-11-16):
      satu baris `sensor_readings` **tetap tercipta** setiap kali user menekan prediksi
      (`PredictionController.php:66-75`, `source=manual`), jadi Home tidak selamanya kosong.
      Yang tidak ada adalah **pengirim data otomatis** — kalian mengonfirmasi
      "tidak ada sumber data sensor" (2026-11-16): tidak ada firmware ESP32 di repo, tidak ada
      skrip, tidak ada jalur IoT. Keputusan (a) baru punya tempat setelah kalian memilih
      **P1** (commit firmware yang memang sudah ada) atau **P2** (skrip pengirim `/api/sensor`).
      Saya bisa menulis P2 (±½ hari, tidak mengubah klaim laporan kalau diberi label
      "simulator"), tapi keputusan itu milik kalian karena menyentuh bab IoT di laporan.

> Saya tidak memilihkan (a)/(b) karena dampaknya ke klaim di laporan, bukan ke teknis.

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
- [ ] 5. Verifikasi sendiri di dashboard: halaman *Domains* harus menampilkan dev domain di atas
      (sekadar memastikan tidak salah baca; tidak ada yang perlu dibeli).

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
**Memblokir: M2 (URL produksi di APK)** · ±5 menit, butuh R3

- [ ] 1. Console Firebase → *Remote Config* → **Get started** (gratis).
- [ ] 2. Tambah parameter:
  - [ ] `api_base_url` (string) = `https://<domain-ngrok>/api`
  - [ ] `minimum_supported_version` (string) = `1.0.0`
- [ ] 3. **Publish** nilainya — Remote Config tidak mengirim apa pun selama hanya di-save sebagai draft.
- [ ] 4. Kabari saya daftar nama parameter yang sudah dibuat.

Saya yang menulis kode Flutter-nya (tambah `firebase_remote_config` di `pubspec.yaml`) dan
memverifikasi isinya lewat `flutter test`.

---

## R5 — Keystore release
**Memblokir: M3** · ±15 menit · **jangan lanjut tanpa backup**

Passphrase dibuat oleh kalian, bukan oleh saya — dan jangan sampai hanya saya yang memegangnya.

- [ ] 1. Generate:

  ```sh
  keytool -genkeypair -v -keystore "D:/keystore/smartfarming-release.jks" \
    -keyalg RSA -keysize 2048 -validity 10000 -alias smartfarming
  ```

- [ ] 2. Buat passphrase yang tidak dipakai di tempat lain; simpan di password manager kampus
      atau kertas. **Jangan** masuk repo.
- [ ] 3. Salin `.jks` ke **satu lokasi di luar laptop** (flashdisk / cloud pribadi).
      Tanpa langkah ini: laptop hilang/partsi = semua user uninstall + install ulang APK.
- [ ] 4. Buat `smart_farming/android/key.properties` dengan isi:

  ```
  storePassword=...
  keyPassword=...
  keyAlias=smartfarming
  storeFile=D:/keystore/smartfarming-release.jks
  ```

  Rule `.gitignore` untuk file ini sudah ada dan terverifikasi
  (`smart_farming/android/.gitignore:13` = `key.properties`). Cek-ulang setelah file dibuat:
  `git check-ignore -v smart_farming/android/key.properties` harus mengeluarkan output.
- [ ] 5. Kirim ke saya: **path keystore + alias**, dan konfirmasi langkah 4 sudah ter-`check-ignore`.
      **Jangan kirim passphrase** — saya baca dari file saat build.

---

## R6 — Monitor uptime + backup
**Memblokir: M2.5** · ±5 menit

- [ ] 1. Daftar UptimeRobot (free) → *HTTPS monitor* ke `https://<domain-ngrok>/up`, interval 5 menit,
      notifikasi email ke ≥2 anggota kelompok.
      (`/up` sudah tersedia sebagai health route — lihat `smart_farming/backend/bootstrap/app.php:13`)
- [ ] 2. Kabari saya dashboard-nya aktif (atau kirim URL-nya).
- [ ] 3. Tentukan folder tujuan backup harian. Saya yang menulis job `mysqldump` + rotasinya;
      **lokasi di luar laptop** adalah keputusan kalian (item plan 2.5.7).
      Backup pertama sudah ada dan sudah teruji: `smart_farming/backend/storage/app/private/backup-mysql-2026-11-16.sql`
      (42 KB, 75 baris data kelas) + salinan SQLite sebelum migrasi di folder yang sama. Folder itu
      di-gitignore, jadi **tugasmu hanya menyalinnya ke luar laptop**. Restore kalau perlu:
      `mysql -u root smart_farming < nama-file.sql`.

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

Catatan: tes #3 sengaja tidak saya eksekusi — me-restart laptop mematikan sesi kerja kita dan
menguji autostart dengan cara itu berisiko pada pekerjaan kalian yang belum ter-commit.

---

## R8 — Persetujuan yang harus diucapkan sebelum saya jalan
Saya tidak melakukan ini tanpa kalian bilang ya, karena tidak aman dibatalkan:

- [x] `git commit` / `git push` — **sudah dipakai untuk commit saja** (5 commit milestone + commit
      MySQL ini). **`git push` tidak pernah dijalankan dan tidak akan saya jalankan tanpa izin baru**;
      pekerjaan ada di branch lokal (lihat §18 `docs/PLAN.md`).
- [x] `git rm --cached` untuk `smart_farming/android/build/reports/**`, dan penghapusan
      `smart_farming/backend/AGENTS.md` + `CLAUDE.md` (M0) — selesai `bf94ac0`.
- [x] `composer require kreait/firebase-php` — selesai (M1.1).
- [x] Menjalankan migrasi MySQL yang mengubah data di DB lokal — selesai 2026-11-16
      (`php artisan migrate --force` + `tool/migrate_sqlite_to_mysql.php --apply`).
      `mysqldump` dan salinan SQLite-nya diambil **sebelum** menulis apa pun.
- [ ] Menghentikan proses yang sedang berjalan (php / mysql / redis / ngrok) saat setel ulang service.
      (Yang sudah terjadi hanya menghentikan web server probe milik saya sendiri; MySQL & ngrok
      kalian tidak pernah saya sentuh.)
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
      Ganti dengan passphrase kalian sendiri sebelum ada yang memakai akun itu, dan simpan di
      password manager kampus. Password tidak pernah masuk repo.
- [ ] **Rotasi `FLASK_ML_SHARED_SECRET`** setelah APK beredar: ganti nilai di `backend/.env`
      DAN env proses Flask (`ML_SHARED_SECRET`), lalu restart keduanya. Kalau hanya satu yang
      diganti, semua prediksi balas 503 (lihat catatan di PLAN §6).
- [ ] Konfirmasi: tidak ada file service account / `.env` / `key.properties` yang ikut
      `git add`. Cek cepat: `git status --short | grep -E "\.env|service-account|key.properties"`
      harus kosong.


## Urutan paling efisien
1. **R1 + R3** sekarang → saya bisa langsung mulai M1.1–M1.3 tanpa menunggu item lain.
2. **R2 + R4** → membuka M2 (URL + Remote Config).
3. **R5** → membuka M3 (APK release).
4. **R6** → menutup M2.5.
5. **R7** → dijalankan setelah build pertama jadi; hasil masuk ke RTM.
6. **R10** → kapan saja, tapi sebelum APK benar-benar beredar.
