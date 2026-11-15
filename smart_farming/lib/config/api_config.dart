abstract final class ApiConfig {
  /// Base URL REST API backend Laravel (Flask hanya boleh diakses oleh Laravel).
  /// - Untuk Android Emulator: 'http://10.0.2.2:8000/api'
  /// - Untuk Perangkat Fisik (Physical Device): Ganti dengan IP lokal laptop di jaringan Wi-Fi yang sama
  ///   (contoh: 'http://192.168.1.15:8000/api')
  static const String baseUrl = 'http://10.0.2.2:8000/api';
}
