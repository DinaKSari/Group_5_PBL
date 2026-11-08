/// Rute default saat notifikasi tidak membawa rute spesifik.
/// Nilainya identik dengan `AppRoutes.riwayat` di layer presentation;
/// domain sengaja tidak mengimpor routes.dart agar tetap pure Dart.
const kDefaultNotificationRoute = '/riwayat';

/// Mengekstrak & menstandarisasi rute navigasi dari payload notifikasi.
/// Default ke [kDefaultNotificationRoute] jika data kosong/tanpa kunci 'route'.
/// Menambahkan awalan '/' bila rute belum memilikinya.
String routeFromMessage(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return kDefaultNotificationRoute;
  }
  final rawRoute = data['route']?.toString().trim();
  if (rawRoute == null || rawRoute.isEmpty) {
    return kDefaultNotificationRoute;
  }
  return rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
}

/// Masking token agar token penuh tidak pernah tercetak ke log.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '(kosong)';
  if (token.length <= 12) return token;
  return '${token.substring(0, 12)}...';
}
