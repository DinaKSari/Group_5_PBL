import 'package:flutter/foundation.dart';

import '../core/remote_settings.dart';

abstract final class ApiConfig {
  /// Base URL REST API backend Laravel (Flask hanya boleh diakses oleh Laravel).
  ///
  /// Prioritas: `--dart-define=API_BASE_URL` (menang, dipakai dev LAN) →
  /// `api_base_url` dari Firebase Remote Config → [buildDefault].
  /// Remote Config membuat APK rilis pindah host tanpa build ulang, sementara
  /// dart-define tetap bisa memaksanya kembali ke laptop waktu debugging.
  ///
  /// Default build debug (127.0.0.1) bekerja lewat port forwarding ADB
  /// (lihat tool/run_android.ps1), sehingga tidak bergantung pada IP maupun
  /// kondisi Wi-Fi: tetap jalan di jaringan yang menerapkan client isolation,
  /// maupun saat berpindah jaringan.
  ///
  /// Untuk menjalankan tanpa kabel (HP dan laptop harus saling terjangkau):
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api    # emulator
  ///   flutter run --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api   # satu jaringan dengan laptop
  static const String dartDefineOverride = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Debug/dev = laptop sendiri (127.0.0.1 lewat `adb reverse`).
  /// Rilis = tunnel ngrok kelas, supaya APK yang dibangun sebelum Remote Config
  /// diaktifkan (RUNBOOK R4) tetap bisa dipakai. Remote Config tetap menang di
  /// atas nilai ini, jadi pindah hosting tidak butuh build ulang.
  static const String devDefault = 'http://127.0.0.1:8000/api';
  static const String releaseDefault =
      'https://craftily-handcraft-outboard.ngrok-free.dev/api';

  static String get buildDefault => kReleaseMode ? releaseDefault : devDefault;

  static String resolve({String? remoteValue}) {
    if (dartDefineOverride.isNotEmpty) return _normalize(dartDefineOverride);

    final remote = remoteValue ?? RemoteSettings.apiBaseUrl;
    if (remote != null && remote.trim().isNotEmpty) {
      return _normalize(remote.trim());
    }

    return buildDefault;
  }

  static String get baseUrl => resolve();

  /// `https://x.ngrok-free.dev/` dan `https://x.ngrok-free.dev` harus memberi
  /// hasil yang sama, karena path request selalu ditempel langsung di belakangnya.
  static String _normalize(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
