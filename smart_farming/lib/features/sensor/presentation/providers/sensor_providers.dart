import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/http_sensor_repository.dart';
import '../../domain/repositories/sensor_repository.dart';

/// Pencatatan parameter kebun selalu lewat backend; tidak ada penyimpanan lokal
/// yang bisa membuat dashboard menampilkan angka yang belum diterima server.
final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return HttpSensorRepository();
});
