/// Hasil estimasi model: sisa hari menuju panen dari tanggal input.
class PredictionResult {
  const PredictionResult({
    required this.daysLeft,
    required this.inputDate,
  });

  final int daysLeft;
  final DateTime inputDate;

  DateTime get harvestDate => inputDate.add(Duration(days: daysLeft));
  bool get isReady => daysLeft <= 0;
}
