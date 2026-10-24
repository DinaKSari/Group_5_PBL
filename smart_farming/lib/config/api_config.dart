abstract final class ApiConfig {
  /// Base URL endpoint server backend Flask.
  /// - Untuk Android Emulator: 'http://10.0.2.2:5000'
  /// - Untuk Perangkat Fisik (Physical Device): Ganti dengan IP lokal laptop di jaringan Wi-Fi yang sama
  ///   (contoh: 'http://192.168.1.15:5000')
  static const String baseUrl = 'http://10.0.2.2:5000';
}
