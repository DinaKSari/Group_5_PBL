import '../../../../core/failures.dart';

/// Kontrak layanan notifikasi. Implementasi (FCM, local notification,
/// registrasi device) hidup di layer data — domain tidak tahu Firebase/http.
abstract class NotificationRepository {
  /// Inisialisasi channel, listener foreground/background/terminated.
  /// [onNotificationOpened] dipanggil saat pengguna membuka notifikasi,
  /// berisi rute tujuan yang sudah dinormalisasi (selalu diawali '/').
  /// Mengembalikan token perangkat bila tersedia.
  Future<({String? token, Failure? failure})> initialize({
    required void Function(String route) onNotificationOpened,
  });

  /// Minta izin sistem lalu subscribe topik broadcast bila granted.
  Future<({bool granted, Failure? failure})> requestPermissionAndSubscribe();

  /// Daftarkan token FCM ke backend.
  Future<({bool registered, Failure? failure})> registerDevice(String fcmToken);

  /// Token yang sedang dipegang, atau ambil baru dari Firebase.
  Future<({String? token, Failure? failure})> currentOrFreshToken();
}
