import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../../core/failures.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/notification_route_resolver.dart';
import '../device_registration_client.dart';

/// Top-level background handler — dijalankan di isolate terpisah
/// tanpa BuildContext. Entry point wajib top-level untuk FCM.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Implementasi [NotificationRepository] di atas Firebase Cloud Messaging
/// dan flutter_local_notifications.
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseMessaging? messaging,
    DeviceRegistrationClient? deviceClient,
  })  : _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        _messaging = messaging ?? FirebaseMessaging.instance,
        _deviceClient = deviceClient ?? const DeviceRegistrationClient();

  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _messaging;
  final DeviceRegistrationClient _deviceClient;

  String? _currentFcmToken;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'pengingat_panen',
    'Pengingat Panen Selada',
    description: 'Notifikasi pengingat panen dan perawatan tanaman selada',
    importance: Importance.max,
    playSound: true,
  );

  @override
  Future<({String? token, Failure? failure})> initialize({
    required void Function(String route) onNotificationOpened,
  }) async {
    // 1. Local notifications untuk foreground display
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationOpened(payload);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. Foreground message: tampilkan manual lewat local notification
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
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: targetRoute,
      );
    });

    // 3. Notifikasi dibuka dari background state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationOpened(routeFromMessage(message.data));
    });

    // 4. Terminated state: pesan yang membuka aplikasi saat mati
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        onNotificationOpened(routeFromMessage(initialMessage.data));
      }
    } catch (e) {
      debugPrint('[NotificationRepo] Gagal memeriksa initial message: $e');
    }

    // 5. Token awal + refresh
    return _fetchAndRegisterToken();
  }

  Future<({String? token, Failure? failure})> _fetchAndRegisterToken() async {
    String? token;
    Failure? failure;
    try {
      // Backend mengharapkan FCM token; register/onRegistered memaparkan
      // Firebase Installation ID, jadi getToken tetap dipakai.
      // ignore: deprecated_member_use
      token = await _messaging.getToken();
      if (token != null) {
        _currentFcmToken = token;
        debugPrint('[NotificationRepo] Token FCM: ${maskToken(token)}');
        await _deviceClient.register(token);
      }
    } catch (e) {
      debugPrint('[NotificationRepo] Gagal mengambil token FCM: $e');
      failure = LocalFailure('Token FCM tidak tersedia: $e');
    }

    // ignore: deprecated_member_use
    _messaging.onTokenRefresh.listen((newToken) async {
      _currentFcmToken = newToken;
      debugPrint('[NotificationRepo] Token FCM diperbarui: ${maskToken(newToken)}');
      await _deviceClient.register(newToken);
    });

    return (token: token, failure: failure);
  }

  @override
  Future<({bool granted, Failure? failure})> requestPermissionAndSubscribe() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        await _messaging.subscribeToTopic('info-selada');
        debugPrint('[NotificationRepo] Izin granted & subscribe topik info-selada.');
      } else {
        debugPrint('[NotificationRepo] Izin notifikasi tidak diberikan.');
      }
      return (granted: granted, failure: null);
    } catch (e) {
      debugPrint('[NotificationRepo] Gagal meminta izin notifikasi: $e');
      return (granted: false, failure: LocalFailure('Gagal meminta izin: $e'));
    }
  }

  @override
  Future<({bool registered, Failure? failure})> registerDevice(String fcmToken) {
    return _deviceClient.register(fcmToken);
  }

  @override
  Future<({String? token, Failure? failure})> currentOrFreshToken() async {
    if (_currentFcmToken != null) {
      return (token: _currentFcmToken, failure: null);
    }
    try {
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      _currentFcmToken = token;
      return (token: token, failure: null);
    } catch (e) {
      return (token: null, failure: LocalFailure('Token FCM tidak tersedia: $e'));
    }
  }
}
