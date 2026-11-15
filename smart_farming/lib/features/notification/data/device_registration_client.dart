import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api_client.dart';
import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../domain/usecases/notification_route_resolver.dart';

/// Mengirimkan FCM token ke backend Laravel (POST /api/devices).
class DeviceRegistrationClient {
  DeviceRegistrationClient({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  Future<({bool registered, Failure? failure})> register(String fcmToken) async {
    final masked = maskToken(fcmToken);

    // Tanpa akun (mode Tamu) tidak ada pemilik token ini, jadi tidak didaftarkan.
    if (Session.isGuest || Session.uid == null) {
      debugPrint('[DeviceRegistration] Dilewati: belum ada akun login.');
      return (registered: false, failure: const AuthFailure('Masuk untuk mendaftar perangkat.'));
    }

    try {
      final response = await _api.postJson('/devices', {
        'fcm_token': fcmToken,
        'platform': 'android',
      }, timeout: const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[DeviceRegistration] Device terdaftar ($masked).');
        return (registered: true, failure: null);
      }
      debugPrint('[DeviceRegistration] Gagal ($masked): status ${response.statusCode}.');
      if (response.statusCode == 401) {
        return (registered: false, failure: const AuthFailure('Sesi kedaluwarsa.'));
      }
      return (registered: false, failure: ServerFailure('Status ${response.statusCode}'));
    } catch (e) {
      debugPrint('[DeviceRegistration] Backend tidak terjangkau ($masked): $e');
      return (registered: false, failure: NetworkFailure());
    }
  }
}
