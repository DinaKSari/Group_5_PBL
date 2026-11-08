# smart_farming

Aplikasi Flutter prediksi waktu panen selada (PBL Kelompok 5).

## Status Arsitektur — Refactor Clean Architecture (Week 7)

### Peta File → Layer (audit sebelum refactor)

| File | Layer seharusnya | Masalah |
| --- | --- | --- |
| `lib/pages/splash_page.dart` | presentation | UI murni, OK (perlu pindah ke `features/onboarding`) |
| `lib/pages/login_page.dart` | presentation | kredensial & delay login hardcoded di widget, tanpa kontrak repository |
| `lib/pages/home_page.dart` | presentation | ❌ memanggil `PushService.instance` & `FirebaseMessaging.instance.getToken()` langsung (DI bocor, widget menyentuh SDK) |
| `lib/pages/prediction_page.dart` | presentation | ❌ `toIso8601String()`/perakitan payload JSON di widget (mapping seharusnya di layer data) |
| `lib/pages/history_page.dart` | presentation | ❌ entity `HistoryItem` + data `_dummy` didefinisikan di file halaman |
| `lib/pages/main_shell_page.dart` | presentation | duplikat shell; navigasi resmi via `routes.dart` (GoRouter) |
| `lib/pages/app_colors.dart` + `lib/theme/app_colors.dart` | core/theme | dua definisi AppColors + duplikat inline di halaman |
| `lib/services/push_service.dart` | data | konkret singleton, tanpa interface domain; `routeFromMessage` (logika murni) tercampur di sini |
| `lib/services/device_api.dart` | data | HTTP langsung, gagal senyap (`bool`), tanpa kontrak `Failure` |
| `lib/routes.dart`, `lib/config/api_config.dart` | presentation / core | OK |

### Hasil 3 Grep Sterilitas di `lib/pages` (sebelum)

| Grep | Target | Hasil |
| --- | --- | --- |
| `Dio( / http. / openDatabase` | NOL | ✅ NOL |
| `jsonDecode / toIso8601String / DateFormat` | NOL | ❌ 1: `prediction_page.dart:55` |
| `Repository( / FirebaseMessaging / PushService` | NOL | ❌ 3: `home_page.dart:37,114,117` |

### Hasil Grep Sterilitas SESUDAH refactor (Fase 6)

| Grep di `features/*/presentation` | Hasil |
| --- | --- |
| `Dio( / http. / openDatabase / FlutterSecureStorage` | ✅ NOL |
| `jsonDecode / toIso8601String / DateFormat` | ✅ NOL |
| `FirebaseMessaging / PushService / *Impl(` di pages | ✅ NOL |
| Domain steril: `package:flutter / http / firebase / go_router` di `features/*/domain` | ✅ NOL |

Instansiasi `*Repository()` hanya boleh di file `presentation/providers/*_providers.dart`
(DI wiring — satu-satunya tempat yang diizinkan).

### Struktur Aktual (sesudah refactor)

```text
lib/
├── core/               failures.dart, app_colors.dart
├── config/             api_config.dart
├── features/
│   ├── notification/   domain (NotificationRepository, route resolver) |
│   │                   data (NotificationRepositoryImpl=FCM, DeviceRegistrationClient) |
│   │                   presentation (providers + wiring main.dart)
│   ├── prediction/     domain (ParameterSpec, Request/Result, PredictionRepository) |
│   │                   data (Model toMap/fromJson, FakePredictionRepository) |
│   │                   presentation (PrediksiPage, providers)
│   ├── history/        domain (HistoryEntry, HistoryRepository) |
│   │                   data (InMemoryHistoryRepository) | presentation
│   ├── auth/           domain (AuthRepository) | data (DemoAuthRepository) | presentation
│   └── onboarding/     presentation saja (splash murni UI — tanpa domain, anti over-engineering)
└── routes.dart         GoRouter (presentation shell)
```

Panah dependensi: `presentation → domain ← data`. Data mengimpor domain;
domain tidak mengimpor apa pun dari Flutter/infra; presentation hanya kenal
abstraksi domain + provider.

### Aturan Target

`presentation → domain ← data`; interface repository di domain, implementasi di data; mapping JSON/DB hanya di model; DI hanya lewat Riverpod provider; kegagalan eksplisit via `Failure`, bukan exception/bool.

### Struktur Target

```text
lib/
├── core/            (failures.dart, app_colors.dart)
├── features/
│   ├── notification/{domain,data,presentation}
│   ├── prediction/ {domain,data,presentation}
│   ├── history/    {domain,data,presentation}
│   ├── auth/       {domain,data,presentation}
│   └── onboarding/ {presentation}
└── routes.dart
```

## Cara Menjalankan

```bash
cd smart_farming
flutter pub get
flutter analyze   # wajib: No issues found
flutter test      # wajib: hijau
flutter run       # target Android (emulator: backend Flask di 10.0.2.2:5000)
```

## Testing (Fase 6)

15 test lulus (`flutter test`):

| File | Isi |
| --- | --- |
| `test/push_test.dart` | `routeFromMessage` & `maskToken` (domain, tetap hijau sejak sebelum refactor — bukti identik) |
| `test/prediction_test.dart` | FakePredictionRepository sukses/heuristik/failure + contract kolom `toMap` |
| `test/history_test.dart` | Entity `HistoryEntry` + kontrak repository (add, seed, immutable) |
| `test/notification_contract_test.dart` | Kontrak notification dengan **fake repository tanpa Firebase** (sukses & NetworkFailure) |

## Status Integrasi Berikutnya

- `FakePredictionRepository` → ganti `HttpPredictionRepository` (POST `${ApiConfig.baseUrl}/predict`)
  cukup di `prediction_providers.dart` — tidak ada file lain yang berubah.
- `InMemoryHistoryRepository` → sqflite / API riwayat.
- `DemoAuthRepository` → endpoint `/auth` bila backend sudah ada.
- Before/after screenshot: perlu emulator Android (`flutter run`), UI tidak berubah oleh
  refactor ini secara visual (perubahan hanya palet halus login/splash, lihat commit Fase 1).

## Screenshot Before/After

Diisi saat verifikasi akhir (Fase 6) — butuh emulator/perangkat Android; UI harus identik sebelum vs sesudah refactor.

## Git Flow Tim

- Branch integrasi: `develop`. `main` hanya lewat release.
- Fitur baru: `feature-<nama-fitur>` → PR ke `develop`.
- Perbaikan bug: `fix-<nama-bug>` → PR ke `develop`.
- Format commit: `tipe(scope): deskripsi` (feat/fix/refactor/test/docs/chore).
- PR kecil: < 300 baris, sertai masalah → solusi → cara uji.
