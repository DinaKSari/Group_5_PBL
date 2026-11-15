import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../config/api_config.dart';
import '../../../../core/failures.dart';
import '../../../../core/session.dart';
import '../../../prediction/domain/entities/prediction_request.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import 'in_memory_history_repository.dart';

/// Riwayat dari backend Laravel (GET /api/predictions).
/// addEntry() sengaja no-op: server sudah menyimpan tiap prediksi saat
/// POST /api/predict, menyimpan ulang akan menghasilkan duplikat.
/// Saat server mati (mode demo offline), fallback ke penyimpanan memori.
class HttpHistoryRepository implements HistoryRepository {
  const HttpHistoryRepository({this._client});

  final http.Client? _client;

  @override
  Future<({List<HistoryEntry> items, Failure? failure})> getHistory() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/predictions'
      '${Session.uid == null ? '' : '?user_uid=${Uri.encodeComponent(Session.uid!)}'}',
    );
    try {
      final client = _client ?? http.Client();
      final response = await client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) {
        return (items: <HistoryEntry>[], failure: ServerFailure('Status ${response.statusCode}'));
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = (body['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(_fromJson)
          .toList(growable: false);
      return (items: items, failure: null);
    } catch (e) {
      debugPrint('[HttpHistoryRepository] Fallback ke memori: $e');
      return InMemoryHistoryRepository.instance.getHistory();
    }
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
    await InMemoryHistoryRepository.instance.addEntry(entry);
    return (saved: true, failure: null);
  }
}
