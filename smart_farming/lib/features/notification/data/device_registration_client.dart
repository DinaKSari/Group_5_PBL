import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../core/failures.dart';
import '../../../core/session.dart';
import '../domain/usecases/notification_route_resolver.dart';

/// Mengirimkan FCM token ke backend Laravel (POST /api/devices).
class DeviceRegistrationClient {
  const DeviceRegistrationClient();

  Future<({bool registered, Failure? failure})> register(String fcmToken) async {
    final masked = maskToken(fcmToken);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/devices'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fcm_token': fcmToken,
              'platform': 'android',
              if (Session.uid != null) 'user_uid': Session.uid,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[DeviceRegistration] Device terdaftar ($masked).');
        return (registered: true, failure: null);
      }
      debugPrint('[DeviceRegistration] Gagal ($masked): status ${response.statusCode}.');
      return (registered: false, failure: ServerFailure('Status ${response.statusCode}'));
    } catch (e) {
      debugPrint('[DeviceRegistration] Backend tidak terjangkau ($masked): $e');
      return (registered: false, failure: NetworkFailure());
    }
  }
}
