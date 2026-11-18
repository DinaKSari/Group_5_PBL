/// Input ML murni: parameter pertumbuhan & lingkungan tanaman selada.
/// `location`/`inputDate` bukan fitur ML — ikut dikirim agar backend dapat
/// mencatat riwayat dengan lokasi & tanggal yang benar (bukan default).
class PredictionRequest {
  const PredictionRequest({
    required this.plantAge,
    required this.temperature,
    required this.humidity,
    required this.tds,
    required this.ph,
    this.location,
    this.inputDate,
  });

  final double plantAge;
  final double temperature;
  final double humidity;
  final double tds;
  final double ph;
  final String? location;
  final DateTime? inputDate;
}
