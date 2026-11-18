import '../../domain/entities/sensor_entry.dart';

/// Bentuk kawat (wire) dari [SensorEntry] untuk `POST /api/sensor`.
///
/// Kunci peta SENGAJA sama dengan `kGrowthParameters` (Flutter) dan aturan
/// validate di `SensorController::store()` (Laravel): umur_hst, suhu,
/// kelembapan, tds, ph. Nama lain = 422 di server.
class SensorEntryModel {
  const SensorEntryModel(this.entry);

  final SensorEntry entry;

  static const manualSource = 'manual';

  Map<String, dynamic> toMap() => {
    ...entry.values,
    if (entry.lokasi != null && entry.lokasi!.trim().isNotEmpty)
      'lokasi': entry.lokasi!.trim(),
    'source': manualSource,
  };
}
