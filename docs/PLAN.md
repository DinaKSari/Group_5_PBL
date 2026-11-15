# PLAN PUBLIKASI — Smart Farming Kelompok 5

Target: menjadikan project **layak dipublikasikan ke user nyata** dengan anggaran Rp 0.
Dokumen ini adalah rencana kerja; daftar langkah manual yang hanya bisa dikerjakan manusia
ada di [`RUNBOOK_MANUAL.md`](RUNBOOK_MANUAL.md).

Terakhir diperbarui: 2026-11-16. Semua referensi baris kode sudah diverifikasi pada tanggal ini.

---

## 1. Keputusan yang mengikat plan ini

| Aspek | Keputusan | Konsekuensi |
|---|---|---|
| Hosting | Laptop sendiri + **ngrok dev domain otomatis** (gratis, tanpa beli apa pun) | Uptime mengikuti laptop yang nyala; kuota 20.000 req/bulan membatasi jumlah user |
| TLS | Sertifikat CA dari ngrok (bukan Let's Encrypt) | Tidak perlu LE, tidak perlu domain, tidak ada isu IP SAN di Dart |
| Database | **MySQL** (sudah ada di Laragon) | Wajib sebelum user nyata masuk; menutup risiko korupsi data saat laptop mati paksa |
| Platform | **Android saja** | Semua pekerjaan iOS/ATS dicoret |
| Distribusi | **APK langsung** (bukan Play Store) | Tidak ada auto-update → pakai cek versi via Remote Config |
| Anggaran | Rp 0; keberatan hanya pada **membeli/menyewa domain** | Semua opsi hostname harus gratis (ngrok/DuckDNS) |
| Upgrade opsional | Oracle Always Free + DuckDNS + Let's Encrypt | Tidak memblokir; lihat §9 |
| Nama app | **LettuGrow** (keputusan 2026-11-16) | Label Android + ikon + dokumen mengikuti nama ini di M3 |
| Mode Tamu | **Read-only** (keputusan 2026-11-16) | Guest boleh pakai form prediksi, tidak boleh melihat riwayat/dashboard siapa pun |
| Buffer sensor | **(a) device menabung & retry** (keputusan 2026-11-16) | 🟠 Tertunda — jalur otomatisnya belum ada (§4A); baru bisa dipasang begitu P1/P2 dipilih |
| `applicationId` | **B: `com.lettgrow.app`** (keputusan + dieksekusi manual 2026-11-16) | Android app baru sudah didaftarkan di Console Firebase dan `google-services.json` sudah ditimpa (berisi 2 client). Kerja saya di M3: `applicationId` + `namespace`/`MainActivity.kt` dirapikan |

## 2. Keluar scope (dinyatakan eksplisit, bukan diam-diam)

❌ Build iOS & ATS · ❌ Listing Play Store · ❌ Domain kustom & brand komersial ·
❌ Certificate pinning / IP-address certificate Let's Encrypt · ❌ Layanan monitoring berbayar.

⚠️ Aturan penulisan laporan: **jangan** menyebut "deployment 24/7" atau "siap produksi publik".
Yang benar: *hosting pribadi di perangkat development, akses internet lewat tunnel terkelola,
uptime mengikuti perangkat tersebut*. Ini menggantikan klaim status Release/Deployment 🟢 di
`README.md:799,803` yang hari ini tidak akurat.

## 3. Temuan yang menjadi dasar pekerjaan (hasil audit)

Kondisi saat ini **belum** layak untuk user, bukan karena kurang fitur, tapi karena:

- **Tidak ada sumber data sensor otomatis** → lihat §4A (dikoreksi: prediksi manual tetap
  menghasilkan satu baris `sensor_readings`).

- ✅ **SELESAI M1.1–M1.3 (2026-11-16): Tidak ada autentikasi API.** dulu hanya `/user` yang
  memakai `auth:sanctum`; `/predict`, `/predictions`, `/sensor`, `/sensor/latest`, `/devices`
  terbuka. Sekarang semua berada di belakang middleware `firebase.auth`
  (`app/Http/Middleware/VerifyFirebaseIdToken.php`) dan bukti tesnya ada di
  `tests/Feature/ApiAuthTest.php`.
- ✅ **SELESAI M1.2: Identitas dipercaya dari client.** dulu `PredictionController.php`,
  `SensorController.php`, `DeviceController.php` memakai `user_uid` dari request (IDOR).
  Sekarang uid berasal dari klaim ID token yang diverifikasi server; field `user_uid`
  dihapus dari rules (`PredictionRequest.php`) dan dari body sensor/device.
- ✅ **SELESAI M1.3: Kebocoran data lintas user** yang dulu didokumentasikan sebagai fitur
  (`PredictionController.php:95` "tanpa user_uid → seluruhnya") — riwayat kini selalu
  difilter ke uid hasil verifikasi token. Sisi app (`http_history_repository.dart`,
  guest mode) masih menunggu **M1.4**.
- **APK release masih pakai debug key** (`android/app/build.gradle.kts:38`), `namespace` (`:9`)
  tidak konsisten dengan `applicationId` (`:21`), `minSdk` mengikuti default (`:24`), tidak ada
  R8/proguard, `usesCleartextTraffic="true"` (`AndroidManifest.xml:8`), label masih
  `smart_farming` (`:6`).
- **Kegagalan ditangani diam-diam.** `MonitoringService.fetch()`
  (`lib/features/home/data/monitoring_service.dart:61-101`) hanya punya `finally`, tanpa
  `try/catch`; `home_page.dart:104` merender `ParamGrid(_paramsFrom(MonitoringData()))` saat
  error (tanda hubung, tanpa pesan), dan `http_history_repository.dart:47` jatuh ke memori
  kosong tanpa memberi tahu user bahwa server mati.
- **Persistensi belum ada.** `in_memory_history_repository.dart:7` masih `TODO(persistensi)`.
- ✅ **SELESAI M1.6: Flask bisa diloncati.** dulu `config/services.php` hanya url+timeout,
  `MlInferenceService.php:24` mengirim POST tanpa key, dan `ML/api/app.py:50` `CORS(app)` bebas
  untuk semua origin.
- **Artefak model tidak lengkap di git.** `ML/api/app.py:31-32,53-54` memuat `classifier.joblib`
  & `cluster.joblib`, yang keduanya tidak ter-commit → clone fresh membuat `cls_model`/`cluster_model`
  `None` dan prediksi degradasi diam-diam. `requirements.txt` tidak memuat `xgboost` dan `matplotlib`.
  → **Dua-duanya ditutup 2026-11-16**: `classifier.joblib` + `cluster.joblib` + `features.json` ikut
  ter-commit (`4f25acf`), dan `requirements.txt` dipin ulang ke versi yang *membuat & memuat* artefak
  itu — numpy 2.2.6 (artefak dipickle memakai modul `numpy._core`, jadi pin lama `numpy==1.26.4`
  mustahil memuatnya), xgboost 3.2.0 (wajib ada walau tidak di-import `app.py`, karena unpickle
  `XGBClassifier` butuhnya), plus matplotlib 3.10.9 untuk `train.py` dan flask/flask-cors/joblib
  mengikuti lingkungan lokal yang sudah terbukti jalan.
- ✅ **SELESAI M1.7: Kredensial default** `admin@gmail.com / 12345678` dihapus dari seeder;
  admin Filament kini dibuat dari `ADMIN_EMAIL`/`ADMIN_PASSWORD` di `.env` (seeder menolak jalan
  kalau kosong atau < 12 karakter). `APP_NAME` sudah `LettuGrow`, `APP_DEBUG` diberi peringatan
  wajib false saat tunnel aktif — **masih `true` di `.env` lokal sampai M2 dibuka**.
- **Zero test untuk UI, zero CI.** Semua file di `smart_farming/test/` adalah unit/contract;  `prediction_test.dart:9,19` menguji `FakePredictionRepository`, bukan jalur HTTP yang dipakai.
  `.github/` (root maupun `smart_farming/`) hanya berisi hook `modernize/java-upgrade`, tidak ada
  workflow.

## 4. Peta milestone

```
M0 (bersih-bersih) ──► M1 (KEAMANAN) ──► M2 (MySQL+ngrok) ──► M2.5 (ketahanan) ──► M3 (APK release) ──► DISTRIBUSI
                             │                  │                                        ▲
                             └──────► M4 (UX & kualitas) ───────────────────────────────┘
                                          M5 (CI, ML reproducible, dokumen)  — paralel sejak hari 1
```

Jalur kritis: **M1 → M2 → M3**. Estimasi total ±9–11 hari kerja solo, atau **5–6 hari kalender**
untuk 3 orang paralel.

## 4A. 🟠 Sumber data sensor — dikoreksi 2026-11-16 (bukan blocker total)

Koreksian atas temuan awal saya. Klaim "tidak ada satu pun kode yang menghasilkan data
sensor" **sebagian salah**:

- ✅ **Ada** jalur tulis data sensor: setiap prediksi di app memanggil
  `PredictionController::store`, yang ikut menyimpan satu baris `sensor_readings`
  (`smart_farming/backend/app/Http/Controllers/PredictionController.php:66-75`,
  `source = 'manual'`). Jadi `GET /api/sensor/latest` **tidak** selamanya `null` — selama
  user pernah menekan prediksi, halaman Home menampilkan parameter prediksi terakhir.
- ✅ Tidak ada firmware/ESP32/Arduino di repo (`find` untuk
  `esp32|firmware|arduino|sketch|iot|.ino` = kosong) — ini tetap benar, dan kalian
  mengonfirmasi "tidak ada sumber data sensor" (2026-11-16).
- ✅ Tidak ada Filament resource sensor (`backend/app/Filament/Resources` hanya `Predictions`).
- ✅ Satu-satunya pemanggil `POST /api/sensor` secara langsung tetap hanya
  `backend/tests/Feature/SensorApiTest.php`.

Sisa masalah yang sebenarnya: **data sensor hanyalah efek samping form prediksi**
(user mengetik suhu/kelembapan/TDS/pH sendiri). Tidak ada pembaruan otomatis antar-prediksi,
dan angka yang muncul di dashboard adalah angka ketikan user, bukan pembacaan perangkat.
Konsekuensinya untuk laporan: bab IoT harus ditulis sebagai "pencatatan parameter manual +
prediksi ML", bukan "monitoring sensor real-time dari perangkat", kecuali firmware nyata
dikonsumsi.

Pekerjaan yang masih bisa dipilih:

| Opsi | Isi | Biaya | Konsekuensi laporan |
|---|---|---|---|
| P1 | Commit firmware ESP32 yang sudah ada (kalau memang ada di perangkat/laptop anggota) | 0 | Klaim IoT utuh; butuh buffer retry (keputusan a) di firmware + kredensial device sendiri (lihat catatan route `iot` di §6/M1) |
| P2 | Tulis skrip pengirim data (Python/PHP command) yang mem-POST `/api/sensor` | ½ hari | Jujur disebut "simulator/emulator perangkat" |
| P3 | Filament resource SensorReadings → admin bisa melihat/mengoreksi catatan | ½ hari | Tidak mengubah klaim user-facing, hanya operasional |
| P4 | Entri sensor manual terpisah di app (di luar form prediksi) | ½ hari | Monitoring jadi "pencatatan manual" yang eksplisit |

Rekomendasi saya: karena (a) buffer-retry sudah kalian pilih tapi tidak ada kode pengirim,
jalur termurah adalah **P1 kalau firmware ada; kalau tidak, P2 untuk demo + P3 untuk
operasional**. Keputusan ini tetap milik kalian karena mengubah klaim bab IoT di laporan.

## 5. M0 — Bersih-bersih repo & dokumen · ½ hari

- [x] Copot artefak build & file internal dari git: `smart_farming/android/build/reports/**`,
      `ML/api/__pycache__/`, `smart_farming/backend/AGENTS.md`, `smart_farming/backend/CLAUDE.md`
      — **selesai 2026-11-16** (`bf94ac0`), plus `.gitignore` & `.gitattributes` di root repo.
- [x] Commit ±27 file modified + untracked yang menggantung, **dipecah per milestone**, bukan `git add -A`
      — **selesai 2026-11-16**: 5 commit (`bf94ac0`, `4f25acf`, `58c690b`, `bdab2d3`, `db34ddd`),
      semua di branch lokal `feature-backend-integration`, **belum di-push**.
- [x] Lengkapi `ML/api/requirements.txt` (`xgboost`, `matplotlib`, pin versi) dan commit
      `ML/api/artifacts/classifier.joblib` + `cluster.joblib` — **selesai 2026-11-16**; pin
      mengikuti lingkungan yang dipakai melatih (lihat catatan §3).
- [ ] File dokumen baru: `LICENSE`, `CHANGELOG.md`, `PRIVACY_POLICY.md`, `docs/DEPLOYMENT.md`,
      `docs/USER_MANUAL.md`.
- [ ] Isi `ML/README.md` (saat ini satu baris) dan ganti `backend/README.md` boilerplate Laravel.

**DoD**: clone fresh → `composer install`, `pip install -r ML/api/requirements.txt`,
`flutter pub get`, `python ML/api/train.py` sukses tanpa manual hacking.

## 6. M1 — Keamanan & identitas · 2–3 hari · 🔴 BLOCKER

> Tidak ada satu baris pun boleh di-expose lewat ngrok sebelum milestone ini selesai.
> Versi LAN yang bocor berubah menjadi kebocoran publik begitu tunnel aktif.

| # | Pekerjaan | Titik kode |
|---|---|---|
| ✅ 1.1 | `composer require kreait/firebase-php` (izin RUNBOOK R8) + middleware `VerifyFirebaseIdToken` — validasi issuer/aud/expiry, uid diambil dari token | `backend/bootstrap/app.php:15-17`; folder `app/Http/Middleware` (baru) |
| ✅ 1.2 | Terapkan ke **semua** route API; buang `user_uid` dari input client | `backend/routes/api.php:13-19`, `PredictionController.php:32-33,52,69,100`, `SensorController.php:23,42`, `DeviceController.php:20,27` |
| ✅ 1.3 | `authorize()` nyata + regression test lintas user (A akses data B → 403) | `app/Http/Requests/PredictionRequest.php:9-12`, `tests/Feature/PredictionApiTest.php` |
| ✅ 1.4 | Flutter: kirim idToken segar per request (`getIdToken(refresh: true)`), auto-logout saat 401, `redirect` guard GoRouter | `http_prediction_repository.dart`, `http_history_repository.dart:24-33`, `monitoring_service.dart:61-66`, `device_registration_client.dart:19-28`, `lib/routes.dart:27`, `lib/main.dart:25` |
| ✅ 1.5 | Eksekusi keputusan RUNBOOK R1 untuk mode Tamu; riwayat tidak pernah kembali tanpa filter uid | `splash_page.dart:300-303`, `http_history_repository.dart:27`, `PredictionController.php:95,100` |
| ✅ 1.6 | Flask hanya boleh dipanggil Laravel: header secret + bind `127.0.0.1` | `ML/api/app.py:50,112,188`, `backend/config/services.php:38-41`, `app/Services/MlInferenceService.php:24` |
| ✅ 1.7 | Hapus kredensial & data sensitif: admin seeder dari env, `APP_DEBUG=false` untuk jalur publik, stop simpan `fcm_token` mentah di log | `DatabaseSeeder.php:22-23`, `backend/.env.example:4`, `DeviceController.php:27` |
| ✅ 1.8 | Service account dari file privat (sudah terverifikasi di-ignore oleh `storage/app/private/.gitignore:1`), `FIREBASE_CREDENTIALS`/`FIREBASE_PROJECT_ID` ditambahkan ke `.env.example` + `.env` (path, bukan isi) | RUNBOOK R3 |

**DoD**: ✅ **tercapai 2026-11-16** — nol endpoint API yang melayani data tanpa idToken
valid (`tests/Feature/ApiAuthTest.php`), tidak ada query/body yang memakai `user_uid` kiriman
client (Laravel 29 tes + Flutter 31 tes hijau), mode Tamu read-only ditegakkan di layer data
(`test/api_auth_contract_test.dart`), Flask menolak panggilan tanpa `X-ML-Token` yang cocok
(diverifikasi live: tanpa token → 401, token benar → 200).

> ⚠️ **Konsekuensi M1.6 untuk kalian (berlaku mulai sekarang):** microservice Flask hanya
> melayani `/predict` kalau env `ML_SHARED_SECRET` saat Flask jalan **sama persis** dengan
> `FLASK_ML_SHARED_SECRET` di `backend/.env`. Kalau kalian menyalakan Flask tanpa env itu,
> semua prediksi balas **503** dengan pesan "Microservice ML menolak permintaan". Nyalakan dengan:
>
> ```powershell
> $env:ML_SHARED_SECRET = (Select-String '^FLASK_ML_SHARED_SECRET=' backend\.env).Line.Split('=')[1]
> python MLpipp.py        # default bind sekarang 127.0.0.1:5000, bukan 0.0.0.0
> ```
> Endpoint `/health` tetap publik (dipakai UptimeRobot), `/devices` Flask dihapus karena
> no-op dan meniru endpoint Laravel.

## 7. M2 — MySQL + ngrok · 1 hari

| Pekerjaan | Catatan |
|---|---|
| ✅ Migrasi `DB_CONNECTION=mysql` | **Selesai 2026-11-16** — `smart_farming` (utf8mb4_unicode_ci) jadi DB aktif; schema dibuat lewat `php artisan migrate --force`, lalu 75 baris data lama dipindah utuh (id & timestamp dipertahankan) oleh `tool/migrate_sqlite_to_mysql.php`. Menutup risiko **korupsi data** saat laptop mati tidak bersih. Backup SQLite asli: `backend/storage/app/private/backup-sqlite-2026-11-16.sqlite` (ter-gitignore) |
| ✅ Pindahkan `SESSION_DRIVER` / `CACHE_STORE` dari `database` | **Selesai 2026-11-16** → `file`. `QUEUE_CONNECTION` sengaja tetap `database` (belum ada consumer; Redis tidak berjalan di laptop ini, dan tabel `jobs` lokal kosong sehingga tidak ada yang tertinggal) |
| `API_BASE_URL` diambil dari **Firebase Remote Config** | menggantikan `lib/config/api_config.dart:10-12`; bonus: pindah ngrok ↔ VPS tanpa rebuild APK, plus `minimum_supported_version` |
| nyalakan `ngrok http 8000` → dev domain gratis `https://craftily-handcraft-outboard.ngrok-free.dev` | ⚠️ **Jangan** pakai "Create Domain" — *reserved static domain* itu fitur **berbayar**. Dev domain otomatis & tidak berubah saat restart. Agent harus ≥3.29 (Laragon bawa 3.1.0 → sudah di-update ke 3.39.13) |
| **Hemat kuota ngrok free (20.000 req/bulan, 1 GB/bulan)** | Endpoint agregat `GET /api/dashboard` (sensor + prediksi terakhir = 1 request, menggantikan 2 request di `monitoring_service.dart:65-66`); provider jangan auto-dispose agar pindah tab tidak fetch ulang; **dilarang** polling `<Timer.periodic>`; tambah header `ngrok-skip-browser-warning` + User-Agent app |
| `/up` (Laravel, `bootstrap/app.php:13`) dan `/health` (Flask, `ML/api/app.py:92`) menjadi target health check & monitoring | dipakai M2.5 |
| ✅ Putuskan `/devices` Flask | **Dihapus 2026-11-16** bersama pengerasan M1.6 — route no-op yang cuma meniru endpoint Laravel (`POST /api/devices` milik app tetap ada di `DeviceController@store`) |
| Prosedur VPS/nginx/LE **dipindah** ke lampiran `docs/DEPLOYMENT.md` | bukan hilang, hanya ditunda (§9) |

**DoD**: HP memakai 4G (bukan Wi-Fi kampus) berhasil registrasi → prediksi → melihat riwayat.

## 8. M2.5 — Ketahanan laptop-sebagai-server · 1 hari *(milestone baru)*

| # | Risiko yang ditutup | Pekerjaan |
|---|---|---|
| ✅ 2.5.1 | Edge ngrok hidup tapi backend mati → balas **halaman HTML**, app crash di `jsonDecode` | **Selesai 2026-11-16 bersama M1.4**: `ApiClient::jsonBody()` menolak non-JSON; dipakai di monitoring & riwayat; prediksi punya pesan kegagalan sendiri |
| 2.5.2 | Setelah boot, MySQL/ngrok tidak jalan → `502` padahal tunnel "hijau" | `deploy/windows-autostart/` (Task Scheduler XML): MySQL → web server → ngrok, berurutan + retry + log |
| 2.5.3 | `artisan serve` single-process & firewall "public network" | Ganti ke nginx/Apache + PHP-CGI Laragon, atau set `PHP_CLI_SERVER_WORKERS` (`.env.example:18` saat ini di-comment); firewall rule; `powercfg` sleep-off |
| 2.5.4 | User tidak tahu server mati (`home_page.dart:104` tanda hubung) | Health banner via `GET /up` saat app resume → "Server offline, data terakhir pukul X" |
| 2.5.5 | Reading sensor saat laptop mati **hilang permanen** | Eksekusi keputusan RUNBOOK R1: buffer+retry sisi device, atau tandai gap eksplisit |
| 2.5.6 | Agent ngrok mati tanpa diketahui | UptimeRobot free ping `/up` tiap 5 menit (RUNBOOK R6) |
| 2.5.7 | Data kelas tidak ada backupnya | `mysqldump` harian + rotasi, hasil di luar laptop |

**DoD**: laptop dimatikan paksa → dinyalakan → tanpa perintah manual apa pun, layanan pulih ≤2 menit
dan user melihat status yang benar selama downtime.

## 9. M3 — Build APK release · 1 hari

- [ ] Keystore release menggantikan `signingConfigs.getByName("debug")`
      (`android/app/build.gradle.kts:38`) + `key.properties` (RUNBOOK R5).
- [ ] `isMinifyEnabled` / `isShrinkResources` + proguard rules (belum ada di seluruh tree `android/`).
- [ ] Samakan `namespace` (`build.gradle.kts:9`) dengan `applicationId` (`:21`), tetapkan `minSdk` (`:24`) final.
- [ ] **Hapus `usesCleartextTraffic="true"`** (`AndroidManifest.xml:8`) — wajib, transport sudah HTTPS.
- [ ] `android:label` jadi nama produk (`AndroidManifest.xml:6`), ikon + splash
      (`flutter_launcher_icons`, `flutter_native_splash` — belum ada di `pubspec.yaml`),
      `versionName`/`versionCode` + `description` yang masih "A new Flutter project.".
- [ ] Copot kode demo: `demo_auth_repository.dart` (menerima kredensial apa pun) dan
      `fake_prediction_repository.dart` beserta simpul DI-nya.
- [ ] Mekanisme update APK-manual: cek `versionCode` vs Remote Config → prompt unduh APK baru.

**DoD**: `flutter build apk --release` dan `appbundle` resign dengan keystore sendiri,
terpasang dan berfungsi di device nyata lewat 4G.

## 10. M4 — Kualitas yang dirasakan user · 2–3 hari

- [ ] State error jujur + tombol "Coba Lagi" di `home_page.dart:104` (pola yang sama untuk semua provider).
- [ ] Cache lokal riwayat (sqflite) menggantikan `in_memory_history_repository.dart:7` →
      data terakhir tetap terbaca saat server mati, tidak lenyap saat restart.
- [ ] **Hapus akun** (kewajiban privasi: data personal + FCM token kita simpan), ubah password,
      fungsikan checkbox "Ingat saya" (`login_page.dart:301`), validasi email nyata
      (`login_page.dart:233` hanya `contains('@')`).
- [ ] Crashlytics + `runZonedGuarded` (Firebase sudah terpasang; free tier cukup).
- [ ] Widget test alur login → prediksi → riwayat (sekarang 0 test widget),
      perketat `analysis_options.yaml:33` (`rules:` yang kini hanya include `flutter_lints`).
- [ ] Notifikasi: jangan subscribe `info-selada` tanpa kondisi
      (`notification_repository_impl.dart:157`), tangani pesan di `firebaseMessagingBackgroundHandler`
      (`:13-16`) yang sekarang hanya `Firebase.initializeApp()` — notifikasi dari background tidak tampil,
      dan buang `// ignore: deprecated_member_use` di `:121,133,180`.

**DoD**: dengan server dimatikan, tidak ada layar yang kosong tanpa penjelasan; tidak ada crash tak tercatat.

## 11. M5 — Otomasi, ML reproducible, bukti QA · 1–2 hari (paralel sejak hari 1)

- [ ] `.github/workflows/ci.yml`: job Flutter (`analyze`, `test`, `build apk`), job Laravel
      (`php artisan test`), job ML (`pytest ML/api/test_app.py`). CI-lah yang menjaga M1 tidak regresi.
- [ ] `train.py` menghasilkan artefak yang persis dimuat `app.py:31-34,52-54`; metrik akhir dicatat
      di `ML/README.md`.
- [ ] Koreksi `README.md:106-107`: klaim "identitas user berasal dari Firebase Auth" menyesatkan
      karena baris 107 sendiri mengakui `user_uid` dikirim bersama request — baru benar setelah M1
      selesai (dan kalimatnya harus menyebut validasi token, bukan sekadar pengiriman uid), dan status Release/Deployment 🟢 (`README.md:803`, tabel di blok `README.md:761-806`).
- [ ] `Documents/QA/RTM_Kelompok5.xlsx` + skenario uji diisi hasil nyata, `Screenshots/` diperbarui
      ke UI final, kolom bukti test diisi link workflow CI yang hijau.

## 12. Gate — kapan APK boleh didistribusikan

- [ ] **Home menampilkan data sensor nyata** (keputusan §4A sudah dieksekusi, bukan kosong)
- [ ] Tidak ada endpoint API yang melayani data tanpa idToken (test lintas-user hijau)
- [ ] Mode Tamu tidak mengembalikan data user lain
- [ ] Flask menolak request tanpa secret
- [ ] DB = MySQL, `APP_DEBUG=false` di jalur publik, tidak ada stack trace yang bocor
- [ ] APK release ditandatangani keystore sendiri, `usesCleartextTraffic` hilang
- [ ] Restart laptop → layanan pulih tanpa perintah manual
- [ ] Server mati → app menampilkan "server offline", bukan layar kosong
- [ ] CI hijau di 3 stack; `LICENSE` + `PRIVACY_POLICY.md` tersedia
- [ ] Ada jalur nyata bagi user untuk menghapus akun & datanya
- [ ] Semua tes RUNBOOK R7 terisi, termasuk yang GAGAL ditulis apa adanya

## 13. Pembagian tim & jadwal

| Orang | Milestone | Hari |
|---|---|---|
| A (backend) | M1 → M2 → M5 (job Laravel/ML) | 3 + 1 + 0.5 |
| B (mobile) | M4 → M3 | 3 + 1 |
| C (infra & dokumen) | M0 → M2.5 → M5 (CI, README, RTM, dokumen) | 0.5 + 1 + 1.5 |

Urutan manual kalian (RUNBOOK R1 → R3 → R2 → R4 → R5 → R6 → R7) sudah dirancang agar tidak
menunggu: begitu R1 + R3 masuk, M1 bisa jalan tanpa keputusan hosting apa pun.

## 14. Risiko residual yang tidak bisa dihilangkan

1. **Uptime mengikuti laptop.** Tidak ada yang bisa memperbaikinya tanpa perangkat yang menyala 24/7.
2. **Tidak ada SLA / dukungan.** Kalau demo dan laptop mati, plan B hanya "nyalakan laptop".
3. **Keamanan ngrok = keamanan laptop.** Laptop yang sama dipakai kerja kuliah lain; satu tunnel aktif
   berarti permukaan serangan laptop ikut naik. Jangan expose port lain lewat ngrok.
4. **Backup = fisik laptop.** Data semua user ada di satu disk yang sama dengan tugas kuliah lain.
5. **Free tier bisa berubah.** Kebijakan ngrok/Oracle/LE dipantau saat implementasi.
   Untuk ngrok, dua batas yang paling mungkin kalian tabrak justru **kuota bulanannya**
   (20.000 request HTTP + 1 GB keluar): kalau terlampaui, tunnel menolak traffic sampai
   siklus berikutnya dan app terlihat "mati". Itu sebabnya endpoint agregat + tidak ada
   auto-poll di §7 bukan optimasi, tapi syarat. Kalau jumlah user tumbuh, fallback tanpa
   uang = Cloudflare quick tunnel (`cloudflared`, hostname acak tiap start) yang
   dipasangkan ke pointer URL di Remote Config — butuh ±1 hari pekerjaan tambahan.

## 15. Lampiran — upgrade yang tertunda (opsional, tidak memblokir)

Oracle Always Free (2 OCPU ARM / 12 GB / 200 GB, tanpa kartu untuk beberapa region — kartu virtual
& prepaid ditolak) + DuckDNS gratis + Let's Encrypt (HTTP-01) + nginx + php-fpm + gunicorn.
Detail prosedurnya akan ditulis di `docs/DEPLOYMENT.md` saat M2 selesai, supaya tetap ada sebagai
opsi tanpa biaya dan **tetap tanpa membeli domain**.

## 16. Log progres & perubahan lingkungan

### 2026-11-16 — persiapan M1
| Perubahan | Detail | Reversibel? |
|---|---|---|
| Keputusan tercatat | Nama app **LettuGrow**, Mode Tamu **read-only**, Buffer sensor **(a)** (tertunda §4A) | — |
| `C:\laragon\bin\php\php-8.5.5-nts\php.ini` | Ekstensi `sodium` diaktifkan (`php_sodium.dll` sudah ada, hanya di-comment). Tanpa ini `kreait/firebase-php` tidak bisa dipasang di PHP 8.5 | Ya (comment ulang barisnya) |
| `ngrok config add-authtoken` | Token tersimpan di `%LOCALAPPDATA%\ngrok\ngrok.yml`, **tidak masuk repo**. ⚠️ Regenerate setelah M2 stabil karena sempat lewat chat | Ya (`ngrok config add-authtoken <baru>`) |
| MySQL | Database baru **`smart_farming`** dibuat (`utf8mb4_unicode_ci`); `laravel`, `filamentpbl`, `lettuce_farming` tidak disentuh | `DROP DATABASE smart_farming` |
| `backend/composer.json` + `.lock` | `kreait/firebase-php ^8.6` ditambahkan | `git checkout` kedua file |
| Dependency security | `composer update` → **16 advisory pada 9 paket menjadi 0**. Bumps mayor-minor: filament `5.8.1→5.11.3`, laravel/framework `13.31.0→13.42.0`, league/commonmark `2.10.1→2.10.7`, sanctum `4.3.3→4.4.0` | `git checkout composer.lock && composer install` |
| Verifikasi | `php artisan test` → **14 passed (60 assertions)**; `adb devices` → `EQFUD64HBIZDQKTW device` | — |
| ngrok agent | `ngrok update` 3.1.0 → **3.39.13** (agent lama ditolak server: `ERR_NGROK_121`, minimal 3.29.0) | Restore Laragon lama, tapi tunnel tidak akan jalan |
| Dev domain terbaca | `https://craftily-handcraft-outboard.ngrok-free.dev` — **gratis, tidak perlu Create Domain** (itu fitur berbayar). Probe dilakukan ke port mati 8899 lalu dimatikan (0 proses ngrok tersisa) | — |

Catatan: `mysql -u root` di Laragon kalian **tanpa password**. Aman selama hanya localhost (ngrok
hanya meneruskan 8000, bukan 3306), tapi akan saya kunci sebagai bagian M2.5.

Belum selesai dari M1: tidak ada — `VerifyFirebaseIdToken` + wiring route + penghapusan
`user_uid` dari client semuanya sudah jalan dan teruji (lihat §17).

## 17. Log progres M1 — 2026-11-16 (autentikasi API, read-only tamu, Flask internal)

**Laravel (`smart_farming/backend/`)** — file baru: `app/Support/FirebaseIdentity.php`,
`app/Contracts/FirebaseTokenVerifier.php`, `app/Exceptions/{InvalidIdTokenException,FirebaseConfigMissingException}.php`,
`app/Services/Firebase/KreaitTokenVerifier.php`, `app/Http/Middleware/VerifyFirebaseIdToken.php`,
`tests/Support/StaticTokenVerifier.php`, `tests/Feature/ApiAuthTest.php`.
Diubah: `bootstrap/app.php` (alias `firebase.auth`), `routes/api.php` (semua route API + throttle),
`config/services.php` (`firebase.*`, `flask.secret`), `config/auth.php` (`panel_admin`),
`AppServiceProvider` (singleton verifier), `PredictionRequest` (rules `user_uid/user_email/user_name`
dibuang, `authorize()` nyata), `PredictionController` + `SensorController` + `DeviceController`
(uid & identitas dari klaim token; token FCM tidak lagi ditulis mentah), `DatabaseSeeder`
(admin dari env, tolak password < 12 karakter), `MlInferenceService` (kirim `X-ML-Token`),
`phpunit.xml` (`FIREBASE_CREDENTIALS=""` supaya test tidak pernah menyentuh akun nyata),
`.env` (nilai nyata) & `.env.example` (placeholder kosong).

**Flutter (`smart_farming/`)** — file baru `lib/core/api_client.dart` (ID token segar per request,
header `ngrok-skip-browser-warning`, guard non-JSON, notifier sesi kedaluwarsa) dan
`test/api_auth_contract_test.dart` (9 tes). `Session` mendapat `isGuest`/`clear()`.
`routes.dart`: redirect guard + `refreshListenable`. `main.dart`: sesi bersumber dari
`authStateChanges`, invalidasi dashboard saat resume (bukan polling). Repo HTTP, model request,
`MonitoringService`, registrasi device, splash (tombol Tamu), login/register (flag guest), dan
halaman prediksi/riwayat/home (pesan asli + tombol Masuk) disesuaikan.
**Dihapus:** `lib/features/auth/data/repositories/demo_auth_repository.dart` — kode mati yang
mencetak uid palsu `demo-<email>` (pulihkan dengan `git checkout HEAD -- <path>` kalau perlu).

**ML Flask (`ML/api/app.py`)** — `/predict` dibungkus `internal_only` (401 bila `ML_SHARED_SECRET`
kosong atau tidak cocok), bind default `127.0.0.1` (dulu `0.0.0.0`), `CORS(app)` jadi opt-in lewat
`ML_CORS_ORIGINS`, route `/devices` no-op dihapus. `/health` tetap publik untuk UptimeRobot.

**Verifikasi** — `php artisan test` **29 passed (90 assertions)**; `flutter test` **31 passed**;
`flutter analyze` bersih kecuali 4 info `withOpacity` lama di `prediction_page.dart`; probe live
Flask (port 5057): tanpa token → **401**, token salah → **401**, token benar → **200** dengan
hasil model nyata (`days_left: 25`, cluster 1), `/health` → 200; proses probe sudah dihentikan.

**Luar repo:** `backend/.env` kini berisi `FIREBASE_CREDENTIALS`, `FIREBASE_PROJECT_ID`,
`FLASK_ML_SHARED_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` (file ter-gitignore), `APP_NAME` →
`LettuGrow`; `APP_DEBUG` masih `true` dan **wajib false sebelum ngrok dibuka** (M2).


---

## 18. Log progres M2 (sebagian) — 2026-11-16 (SQLite → MySQL + pin Python)

**Yang berpindah.** `smart_farming/backend/.env` sekarang `DB_CONNECTION=mysql` dengan
`DB_HOST=127.0.0.1`, `DB_PORT=3306`, `DB_DATABASE=smart_farming`, `DB_USERNAME=root`,
`DB_PASSWORD=` (kosong — Laragon), plus `SESSION_DRIVER=file` dan `CACHE_STORE=file`.
`config/database.php` tidak disentuh (blok `mysql`-nya sudah benar); `.env.example` mengikuti
sebagai placeholder.

**Urutan yang dijalankan** (diulang persis ini kalau perlu dari nol):

```
cd smart_farming/backend
# 0. backup SQLite lama (sudah ada: storage/app/private/backup-sqlite-2026-11-16.sqlite)
php artisan migrate --force                 # buat schema di DB smart_farming (9 migrasi, 0 baris)
php ../../tool/migrate_sqlite_to_mysql.php            # dry-run, tidak menulis apa pun
php ../../tool/migrate_sqlite_to_mysql.php --apply    # salin data
"C:/laragon/bin/mysql/mysql-8.0.30-winx64/bin/mysqldump.exe" -u root --single-transaction \
    smart_farming > storage/app/private/backup-mysql-2026-11-16.sql
```

`tool/migrate_sqlite_to_mysql.php` bersifat **idempotent & aman dipakai ulang**: tabel tujuan yang
sudah berisi baris dilewati, hanya kolom yang sama-sama ada yang disalin, `id`/`created_at`/
`updated_at` dipertahankan, `AUTO_INCREMENT` dinaikkan ke max+1, dan `cache`/`cache_locks`/`sessions`
sengaja diabaikan karena driver-nya sudah pindah ke `file`.

**Hasil verifikasi.**

| Tabel | SQLite asal | MySQL setelah salin | AUTO_INCREMENT |
|---|---|---|---|
| `users` | 1 | 1 | 2 |
| `predictions` | 18 | 18 (id 1–19, ada 1 gap lama) | 20 |
| `sensor_readings` | 21 | 21 | 22 |
| `activity_logs` | 31 | 31 | 32 |
| `app_users` | 4 | 4 (id 2–5) | 6 |
| **total tersalin** | | **75 baris** | |

`php artisan test` **29 passed (90 assertions)**; `config('database.default')` = `mysql` dan
model membaca jumlah yang sama lewat Eloquent; `predictions.ml_result` valid sebagai JSON
(`JSON_VALID` = 1) dan cast array berfungsi (`stage=Vegetatif (Pembesaran)`, `days_left=15`);
probe HTTP live: `/up` → 200, `POST /api/predict` tanpa token → 401 (bukan 500), server probe
sudah dihentikan dan port 8000 kembali kosong.

Dump-nya pun **teruji bisa di-restore**: dipulihkan ke DB scratch `zz_restore_probe` (18/21/31
baris cocok), lalu DB scratch itu dihapus. DB kelas asli tidak pernah disentuh selama tes.

**Pin Python (`ML/api/requirements.txt`).** Versi lama mustahil memuat artefak yang sekarang
ter-commit: `model.joblib` dan `cluster.joblib` dipickle oleh numpy 2.x (byte-nya memanggil
`numpy._core`, modul yang baru ada di numpy ≥ 2.0) sementara pin lama `numpy==1.26.4`; dan
`classifier.joblib` adalah `xgboost.sklearn.XGBClassifier` yang tidak bisa di-unpickle tanpa
paket xgboost — padahal `app.py:74-76` memuat model di level modul **tanpa `try`**, jadi
`python app.py` langsung mati. Pin sekarang = lingkungan yang terbukti memuat ketiga model
(diverifikasi lewat `joblib.load` langsung). Konsekuensi: **README/bab ML menyebut LinearRegression
sebagai model regresi terpilih** (bukan XGBoost — XGBoost hanya pemenang klasifikasi), jadi
kalau ada dokumen yang mengklaim "XGBoost untuk prediksi hari panen", itu yang perlu dikoreksi.

**Cabang.** Semua pekerjaan M0–M2 ini ada di branch lokal **`feature-letugrow-m1-keamanan-mysql`**
(dipercabangkan dari `feature-backend-integration`, 6 commit di depan `origin/main`).
**Tidak ada satu pun yang di-push** — `origin` belum melihat kode ini, sesuai permintaan.

**Belum selesai di M2**: `API_BASE_URL` dari Remote Config (RUNBOOK R4), menyalakan ngrok +
konfirmasi dev domain (R2), `APP_DEBUG=false` sebelum tunnel dibuka, dan penguncian password
`root` MySQL. Data lama kelas uji coba (`smoke-test-uid`, `perf-uid` di `predictions`) sengaja
**tidak** saya hapus — bilang saja kalau mau dibersihkan sebelum user nyata masuk.
