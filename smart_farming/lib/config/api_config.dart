abstract final class ApiConfig {
  /// Base URL REST API backend Laravel (Flask hanya boleh diakses oleh Laravel).
  ///
  /// Default 127.0.0.1 bekerja lewat port forwarding ADB (lihat tool/run_android.ps1),
  /// sehingga tidak bergantung pada IP maupun kondisi Wi-Fi: tetap jalan di jaringan
  /// yang menerapkan client isolation, maupun saat berpindah jaringan.
  ///
  /// Untuk menjalankan tanpa kabel (HP dan laptop harus saling terjangkau):
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api    # emulator
  ///   flutter run --dart-define=API_BASE_URL=http://IP-LAPTOP:8000/api   # satu jaringan dengan laptop
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}
