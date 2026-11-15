import '../../../../core/failures.dart';
import '../entities/sensor_entry.dart';

/// Kontrak pencatatan parameter kebun.
/// `null` = tersimpan; selain itu berisi alasan yang boleh ditampilkan apa adanya.
abstract class SensorRepository {
  Future<Failure?> record(SensorEntry entry);
}
