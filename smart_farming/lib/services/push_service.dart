import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../routes.dart';

/// Top-level background message handler.
/// Dijalankan di isolate terpisah tanpa BuildContext dan tanpa Riverpod.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handler top-level khusus background & terminated message.
}

/// Fungsi murni untuk mengekstrak dan menstandarisasi rute navigasi dari data payload notifikasi.
/// Default ke [AppRoutes.riwayat] jika data kosong atau tidak memiliki kunci 'route'.
/// Menambahkan awalan '/' jika format rute belum memilikinya.
String routeFromMessage(Map<String, dynamic>? data) {
  if (data == null || data.isEmpty) {
    return AppRoutes.riwayat;
  }
  final rawRoute = data['route']?.toString().trim();
  if (rawRoute == null || rawRoute.isEmpty) {
    return AppRoutes.riwayat;
  }
  return rawRoute.startsWith('/') ? rawRoute : '/$rawRoute';
}

/// Helper untuk masking token agar tidak pernah mencetak token penuh ke log.
String maskToken(String? token) {
  if (token == null || token.isEmpty) return '(kosong)';
  if (token.length <= 12) return token;
  return '${token.substring(0, 12)}...';
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentFcmToken;
  String? get currentFcmToken => _currentFcmToken;

  void Function(String token)? _onTokenCallback;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'pengingat_panen',
    'Pengingat Panen Selada',
    description: 'Notifikasi pengingat panen dan perawatan tanaman selada',
    importance: Importance.max,
    playSound: true,
  );

  /// Inisialisasi service FCM, Local Notifications, dan listeners
  Future<void> initialize({void Function(String token)? onToken}) async {
    _onTokenCallback = onToken;

    // 1. Inisialisasi flutter_local_notifications untuk foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          appRouter.go(payload);
        }
      },
    );

    // Daftarkan channel notifikasi ke sistem Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 2. Listener foreground message: tampilkan manual lewat local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final targetRoute = routeFromMessage(message.data);

      final title = notification?.title ??
          message.data['title']?.toString() ??
          'Pengingat Panen Selada';
      final body = notification?.body ??
          message.data['body']?.toString() ??
          'Waktunya memantau kondisi selada Anda.';

      _localNotifications.show(
        id: notification.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: targetRoute,
      );
    });

    // 3. Listener saat notifikasi ditekan dari background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final targetRoute = routeFromMessage(message.data);
      appRouter.go(targetRoute);
    });

    // 4. Pengambilan token dan listener token refresh
    await _setupToken();
  }

  /// Setup token dan listener refresh
  Future<void> _setupToken() async {
    try {
      // Keep the FCM token expected by the backend; register/onRegistered exposes a Firebase Installation ID.
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _currentFcmToken = token;
        debugPrint('[PushService] Token FCM: ${maskToken(token)}');
        _onTokenCallback?.call(token);
      }
    } catch (e) {
      debugPrint('[PushService] Gagal mengambil token FCM: $e');
    }

    // Keep listening for refreshed FCM tokens expected by the backend.
    // ignore: deprecated_member_use
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _currentFcmToken = newToken;
      debugPrint('[PushService] Token FCM diperbarui: ${maskToken(newToken)}');
      _onTokenCallback?.call(newToken);
    });
  }

  /// Menangani pesan yang membuka aplikasi dari kondisi terminated (aplikasi mati)
  Future<void> setupTerminatedMessage() async {
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final targetRoute = routeFromMessage(initialMessage.data);
        appRouter.go(targetRoute);
      }
    } catch (e) {
      debugPrint('[PushService] Gagal memeriksa initial message: $e');
    }
  }

  /// Meminta izin notifikasi ke pengguna.
  /// Dipanggil saat pengguna sudah masuk ke halaman utama (bukan di splash screen).
  Future<bool> requestNotificationPermission() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        // Berlangganan topik notifikasi 'info-selada' hanya setelah izin diberikan
        await FirebaseMessaging.instance.subscribeToTopic('info-selada');
        debugPrint(
          '[PushService] Izin notifikasi diberikan & subscribe ke topik info-selada.',
        );
      } else {
        debugPrint('[PushService] Izin notifikasi tidak diberikan.');
      }
      return granted;
    } catch (e) {
      debugPrint('[PushService] Gagal meminta izin notifikasi: $e');
      return false;
    }
  }
}
