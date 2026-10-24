import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'push_service.dart';

class DeviceApi {
  /// Mengirimkan FCM token ke backend server Flask.
  /// Body: {"fcm_token": ..., "platform": "android"}
  /// Menangani error secara tenang tanpa menyebabkan crash jika backend belum berjalan.
  static Future<bool> registerDevice(String fcmToken) async {
    final masked = maskToken(fcmToken);
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/devices');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fcm_token': fcmToken,
              'platform': 'android',
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[DeviceApi] Device berhasil didaftarkan ke backend ($masked).');
        return true;
      } else {
        debugPrint(
          '[DeviceApi] Gagal mendaftarkan device ($masked): status ${response.statusCode}.',
        );
        return false;
      }
    } catch (e) {
      // Gagal dengan tenang tanpa crash bila backend belum aktif
      debugPrint(
        '[DeviceApi] Backend belum aktif / tidak dapat dijangkau ($masked): $e',
      );
      return false;
    }
  }
}
