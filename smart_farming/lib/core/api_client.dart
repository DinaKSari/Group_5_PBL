import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session.dart';

typedef IdTokenSupplier = Future<String?> Function();

/// Naik setiap kali backend membalas 401; didengarkan guard GoRouter.
final sessionExpiredNotifier = ValueNotifier<int>(0);

/// Backend membalas 401 → sesi lokal tidak berlaku lagi: bersihkan state dan
/// beri tahu UI (guard GoRouter mendengarkan ini untuk mengeluarkan ke login).
void _notifySessionExpired() {
  Session.clear();
  sessionExpiredNotifier.value = sessionExpiredNotifier.value + 1;
}

/// Satu-satunya tempat yang tahu cara memanggil API Laravel: base URL, header,
/// dan ID token Firebase yang menempel padanya.
///
/// Identitas user TIDAK dikirim sebagai field body/query lagi — server membaca
/// uid dari token yang diverifikasi, jadi tidak ada jalur untuk mengaku sebagai
/// petani lain (`docs/PLAN.md` §6 M1.4).
class ApiClient {
  ApiClient({
    this.client,
    IdTokenSupplier? idToken,
    void Function()? onUnauthorized,
  })  : _idToken = idToken ?? _firebaseIdToken,
        _onUnauthorized = onUnauthorized ?? _notifySessionExpired;

  /// null = setiap panggilan memakai `http.Client()` baru lalu ditutup.
  final http.Client? client;
  final IdTokenSupplier _idToken;
  final void Function() _onUnauthorized;

  static const Duration defaultTimeout = Duration(seconds: 10);

  /// ID token segar; Firebase me-refresh otomatis bila mendekati kedaluwarsa.
  /// `null` berarti tidak ada sesi (tamuan / token tidak tersedia).
  Future<String?> idToken() async {
    try {
      return await _idToken();
    } catch (e) {
      debugPrint('[ApiClient] ID token tidak tersedia: $e');
      return null;
    }
  }

  Future<http.Response> get(
    String path, {
    Map<String, String>? query,
    Duration? timeout,
  }) =>
      _send('GET', path, query: query, timeout: timeout);

  Future<http.Response> postJson(
    String path,
    Map<String, dynamic> json, {
    Duration? timeout,
  }) =>
      _send('POST', path, body: json, timeout: timeout);

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await idToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      headers['Content-Type'] = 'application/json';
    }
    // ngrok menampilkan interstitial untuk browser; header ini menandai kita
    // sebagai client programatik sehingga JSON murni yang diterima.
    headers['ngrok-skip-browser-warning'] = 'smart-farming';

    final activeClient = client ?? http.Client();
    final request = http.Request(method, uri.replace(queryParameters: query))
      ..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed =
          await activeClient.send(request).timeout(timeout ?? defaultTimeout);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 401) _onUnauthorized();

      return response;
    } finally {
      // Instance milik sendiri ditutup; client injeksi (repo/persisten) bukan
      // milik kita dan dipakai ulang oleh pemanggil lain.
      if (client == null) activeClient.close();
    }
  }

  /// Body JSON, atau `null` kalau server mengirim bukan JSON — misalnya halaman
  /// HTML ngrok/Laragon saat `artisan serve` mati. Membedakan keduanya di sini
  /// mencegah `jsonDecode` melempar di perangkat user.
  static Map<String, dynamic>? jsonBody(http.Response response) {
    final type = response.headers['content-type'] ?? '';
    if (!type.contains('json')) return null;
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}

Future<String?> _firebaseIdToken() async =>
    FirebaseAuth.instance.currentUser?.getIdToken(true);
