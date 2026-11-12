import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../core/session.dart';

class SensorSnapshot {
  const SensorSnapshot({
    required this.ph,
    required this.tds,
    required this.suhu,
    required this.kelembapan,
    required this.lokasi,
    required this.updatedAt,
  });

  final double ph;
  final double tds;
  final double suhu;
  final double kelembapan;
  final String lokasi;
  final DateTime updatedAt;
}

class PredictionSnapshot {
  const PredictionSnapshot({
    required this.daysLeft,
    required this.harvestDate,
    required this.currentHst,
    required this.totalHst,
  });

  final int daysLeft;
  final DateTime harvestDate;
  final double currentHst;
  final int totalHst;
}

class MonitoringData {
  const MonitoringData({this.sensor, this.prediction});

  final SensorSnapshot? sensor;
  final PredictionSnapshot? prediction;

  bool get isEmpty => sensor == null && prediction == null;
}

/// Ambil data dashboard dari backend Laravel: pembacaan sensor terbaru
/// (GET /api/sensor/latest) + prediksi terakhir (GET /api/predictions?limit=1).
class MonitoringService {
  const MonitoringService();

  Uri _url(String path, [Map<String, String>? query]) {
    final params = {...?query, 'user_uid': ?Session.uid};
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: params.isEmpty ? null : params,
    );
  }

  Future<MonitoringData> fetch() async {
    final client = http.Client();
    try {
      final responses = await Future.wait([
        client.get(_url('/sensor/latest'), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8)),
        client.get(_url('/predictions', {'limit': '1'}), headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8)),
      ]);

      SensorSnapshot? sensor;
      final sensorBody = jsonDecode(utf8.decode(responses[0].bodyBytes)) as Map<String, dynamic>;
      final s = sensorBody['data'] as Map<String, dynamic>?;
      if (s != null) {
        sensor = SensorSnapshot(
          ph: (s['ph'] as num).toDouble(),
          tds: (s['tds'] as num).toDouble(),
          suhu: (s['suhu'] as num).toDouble(),
          kelembapan: (s['kelembapan'] as num).toDouble(),
          lokasi: s['lokasi']?.toString() ?? 'Kebun',
          updatedAt: DateTime.tryParse(s['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }

      PredictionSnapshot? prediction;
      final predBody = jsonDecode(utf8.decode(responses[1].bodyBytes)) as Map<String, dynamic>;
      final items = (predBody['data'] as List<dynamic>? ?? []);
      if (items.isNotEmpty) {
        final p = items.first as Map<String, dynamic>;
        final params = (p['params'] as Map<String, dynamic>?) ?? const {};
        prediction = PredictionSnapshot(
          daysLeft: (p['days_left'] as num?)?.toInt() ?? 0,
          harvestDate: DateTime.tryParse(p['harvest_date']?.toString() ?? '') ?? DateTime.now(),
          currentHst: (params['umur_hst'] as num?)?.toDouble() ?? 0,
          totalHst: (p['estimated_total_hst'] as num?)?.toInt() ?? 0,
        );
      }

      return MonitoringData(sensor: sensor, prediction: prediction);
    } finally {
      client.close();
    }
  }
}
