import 'package:http/http.dart' as http;

import '../../../core/api_client.dart';
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
  const MonitoringData({this.sensor, this.prediction, this.failure});

  final SensorSnapshot? sensor;
  final PredictionSnapshot? prediction;

  /// Pesan kegagalan yang boleh ditampilkan apa adanya (mis. "Masuk untuk
  /// melihat data"). null = data diambil tanpa masalah.
  final String? failure;

  bool get isEmpty => sensor == null && prediction == null;
}

/// Ambil data dashboard dari backend Laravel: pembacaan sensor terbaru
/// (GET /api/sensor/latest) + prediksi terakhir (GET /api/predictions?limit=1).
class MonitoringService {
  MonitoringService({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  static const _timeout = Duration(seconds: 8);

  Future<MonitoringData> fetch() async {
    // Tamu read-only: dashboard milik petani lain tidak pernah diminta.
    if (Session.isGuest) {
      return const MonitoringData(
        failure: 'Masuk untuk melihat pemantauan kebun kalian.',
      );
    }

    try {
      final responses = await Future.wait([
        _api.get('/sensor/latest', timeout: _timeout),
        _api.get('/predictions', query: const {'limit': '1'}, timeout: _timeout),
      ]);

      SensorSnapshot? sensor;
      if (responses[0].statusCode == 401) {
        return const MonitoringData(failure: 'Sesi kedaluwarsa, masuk kembali.');
      }
      // jsonBody (bukan jsonDecode mentah) supaya halaman HTML dari ngrok saat
      // backend mati tidak meng-crash app.
      final sensorBody = ApiClient.jsonBody(responses[0]);
      if (sensorBody == null) {
        return const MonitoringData(
          failure: 'Server mengembalikan respons yang tidak dapat dibaca.',
        );
      }
      final s = sensorBody['data'] as Map<String, dynamic>?;
      if (s != null) {
        sensor = SensorSnapshot(
          ph: (s['ph'] as num?)?.toDouble() ?? 0,
          tds: (s['tds'] as num?)?.toDouble() ?? 0,
          suhu: (s['suhu'] as num?)?.toDouble() ?? 0,
          kelembapan: (s['kelembapan'] as num?)?.toDouble() ?? 0,
          lokasi: s['lokasi']?.toString() ?? 'Kebun',
          updatedAt: DateTime.tryParse(s['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
      }

      PredictionSnapshot? prediction;
      final predBody = ApiClient.jsonBody(responses[1]);
      final items = (predBody?['data'] as List<dynamic>? ?? []);
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
    } catch (e) {
      return MonitoringData(failure: 'Server tidak terjangkau (${e.runtimeType}).');
    }
  }
}
