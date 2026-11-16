import '../../../prediction/domain/entities/parameter_spec.dart';

/// Satu pembacaan parameter kebun yang dicatat tangan oleh pengguna
/// (keputusan P4: tidak ada perangkat IoT, jadi angka ini adalah pencatatan
/// manual, bukan telemetri).
///
/// Nilainya disimpan TERLEBIH DAHULU sebagai peta `key -> nilai` memakai kunci
/// [kGrowthParameters], sehingga halaman entri dan validasi memakai satu sumber
/// angka yang sama dengan `SensorController::store()` di Laravel.
class SensorEntry {
  const SensorEntry(this.values, {this.lokasi});

  final Map<String, double> values;
  final String? lokasi;

  double of(String key) => values[key]!;

  /// true kalau semua kunci parameter ada dan berada dalam rentang spesifikasinya.
  bool get isComplete => kGrowthParameters.every(
    (spec) =>
        values.containsKey(spec.key) && spec.isAcceptable(values[spec.key]!),
  );
}
