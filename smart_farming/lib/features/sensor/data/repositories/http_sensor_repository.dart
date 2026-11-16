import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/api_client.dart';
import '../../../../core/error_messages.dart';
import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../domain/entities/sensor_entry.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../models/sensor_entry_model.dart';

/// Mencatat parameter kebun lewat `POST /api/sensor` (Laravel).
///
/// Tidak ada penulisan lokal: kalau server menolak, angka itu memang tidak
/// pernah sampai, dan pengguna harus tahu.
class HttpSensorRepository implements SensorRepository {
  HttpSensorRepository({http.Client? client})
    : _api = ApiClient(client: client);

  final ApiClient _api;

  static const _timeout = Duration(seconds: 10);

  @override
  Future<Failure?> record(SensorEntry entry) async {
    // Mode Tamu read-only: tidak ada identitas pemilik pembacaan, jadi
    // jangan berpura-pura mengirim (server akan membalas 401).
    if (Session.isGuest) {
      return const AuthFailure('Masuk untuk mencatat parameter kebun kalian.');
    }

    if (!entry.isComplete) {
      return const LocalFailure(
        'Ada parameter yang kosong atau di luar rentang yang wajar.',
      );
    }

    final http.Response response;
    try {
      response = await _api.postJson(
        '/sensor',
        SensorEntryModel(entry).toMap(),
        timeout: _timeout,
      );
    } on SocketException {
      return const NetworkFailure(ErrorMessages.network);
    } on TimeoutException {
      return const ServerFailure(ErrorMessages.offline);
    } catch (e) {
      debugPrint('[HttpSensorRepository] Error: $e');
      return LocalFailure(ErrorMessages.fromException(e));
    }

    if (response.statusCode == 201 || response.statusCode == 200) return null;

    if (response.statusCode == 401) {
      return const AuthFailure(ErrorMessages.sessionExpired);
    }

    return ServerFailure(_errorMessage(response));
  }

  /// 422 Laravel memakai `errors`, 5xx memakai `message`; keduanya harus
  /// terbaca di perangkat supaya pengguna tahu angka mana yang salah.
  String _errorMessage(http.Response response) {
    final data = ApiClient.jsonBody(response);
    if (data != null) {
      final errors = data['errors'];
      if (errors is Map) {
        final flat = errors.values
            .expand((e) => e is List ? e.map((x) => '$x') : ['$e'])
            .join(', ');
        if (flat.isNotEmpty) return flat;
      }
      final message = data['message'];
      if (message is String &&
          message.isNotEmpty &&
          message != 'Server Error') {
        return message;
      }
    }
    return ErrorMessages.fromResponse(response);
  }
}
