/// Spesifikasi satu parameter lingkungan untuk prediksi.
/// Batas min/max/step adalah aturan bisnis validasi input — hidup di domain.
/// Ikon & widget terkait tetap milik presentation.
class ParameterSpec {
  const ParameterSpec(
    this.key,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.step,
    this.defaultValue,
  );

  final String key, label, unit;
  final double min, max, step, defaultValue;

  int get decimals => step < 1 ? 1 : 0;

  bool isAcceptable(double v) => v >= min && v <= max;

  double clampValue(double v) => v.clamp(min, max).toDouble();
}

/// Fitur ML yang dibutuhkan model regresi (dataset Lettuce Growth Days).
const kGrowthParameters = [
  ParameterSpec('umur_hst', 'Umur Selada', 'hari', 1, 45, 1, 20),
  ParameterSpec('suhu', 'Suhu', '°C', 10, 40, 0.5, 23),
  ParameterSpec('kelembapan', 'Kelembapan', '%', 30, 100, 1, 78),
  ParameterSpec('tds', 'TDS / Nutrisi', 'ppm', 200, 1500, 10, 720),
  ParameterSpec('ph', 'pH Air', '', 4, 9, 0.1, 6.0),
];
