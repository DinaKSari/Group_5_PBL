import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/monitoring_service.dart';

/// Data dashboard (sensor terbaru + prediksi terakhir) dari backend.
/// ref.invalidate saat pull-to-refresh / setelah prediksi baru.
final monitoringProvider = FutureProvider<MonitoringData>((ref) async {
  return const MonitoringService().fetch();
});
