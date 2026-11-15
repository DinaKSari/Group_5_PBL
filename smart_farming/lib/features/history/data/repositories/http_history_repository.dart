import 'dart:async';

import 'package:http/http.dart' as http;

import '../../../../core/api_client.dart';
import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../../prediction/domain/entities/prediction_request.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

/// Riwayat dari backend Laravel (GET /api/predictions).
///
/// Server memfilter hasil ke uid dari ID token, jadi tidak ada parameter
/// `user_uid` di URL. addEntry() sengaja no-op: server sudah menyimpan tiap
/// prediksi saat POST /api/predict.
class HttpHistoryRepository implements HistoryRepository {
  HttpHistoryRepository({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  @override
  Future<({List<HistoryEntry> items, Failure? failure})> getHistory() async {
    // Mode Tamu read-only: riwayat pribadi tidak pernah ditampilkan, dan
    // tidak ada permintaan jaringan yang bisa membocorkan riwayat orang lain.
    if (Session.isGuest) {
      return (
        items: const <HistoryEntry>[],
        failure: const AuthFailure('Masuk untuk melihat riwayat prediksi.'),
      );
    }

    final http.Response response;
    try {
      response = await _api.get('/predictions', query: const {'limit': '50'});
    } on TimeoutException {
      return (
        items: const <HistoryEntry>[],
        failure: const ServerFailure(
          'Server tidak merespons, riwayat belum diperbarui.',
        ),
      );
    } catch (e) {
      // Sengaja tidak jatuh ke cache memori: user harus tahu server tidak
      // terjangkau, bukan melihat daftar kosong yang tampak seperti belum ada
      // prediksi sama sekali.
      return (
        items: const <HistoryEntry>[],
        failure: NetworkFailure('Riwayat tidak dapat diambil.'),
      );
    }

    if (response.statusCode == 401) {
      return (
        items: const <HistoryEntry>[],
        failure: const AuthFailure('Sesi kedaluwarsa, masuk kembali.'),
      );
    }

    if (response.statusCode != 200) {
      return (
        items: const <HistoryEntry>[],
        failure: ServerFailure('Status ${response.statusCode}'),
      );
    }

    final body = ApiClient.jsonBody(response);
    if (body == null) {
      return (
        items: const <HistoryEntry>[],
        failure: const ServerFailure(
          'Respons server tidak dapat dibaca (kemungkinan backend sedang mati).',
        ),
      );
    }

    final items = (body['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);

    return (items: items, failure: null);
  }

  HistoryEntry _fromJson(Map<String, dynamic> json) {
    final params = (json['params'] as Map<String, dynamic>?) ?? const {};
    return HistoryEntry(
      location: json['lokasi']?.toString() ?? 'Kebun',
      inputDate: DateTime.tryParse(json['tanggal_input']?.toString() ?? '') ?? DateTime.now(),
      daysLeft: (json['days_left'] as num?)?.toInt() ?? 0,
      parameters: PredictionRequest(
        plantAge: (params['umur_hst'] as num?)?.toDouble() ?? 0,
        temperature: (params['suhu'] as num?)?.toDouble() ?? 0,
        humidity: (params['kelembapan'] as num?)?.toDouble() ?? 0,
        tds: (params['tds'] as num?)?.toDouble() ?? 0,
        ph: (params['ph'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  @override
  Future<({bool saved, Failure? failure})> addEntry(HistoryEntry entry) async {
    return (saved: true, failure: null);
  }
}
