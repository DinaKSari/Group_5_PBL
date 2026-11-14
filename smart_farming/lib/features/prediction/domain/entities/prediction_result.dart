/// Hasil estimasi lengkap:
/// 1. Regresi: sisa hari menuju panen dari tanggal input
/// 2. Klasifikasi: fase pertumbuhan / kesiapan panen
/// 3. Klusterisasi: profil kondisi lingkungan & nutrisi
class PredictionResult {
  const PredictionResult({
    required this.daysLeft,
    required this.inputDate,
    this.growthStage = 'Vegetatif (Pembesaran)',
    this.stageId = 1,
    this.clusterDesc = 'Kondisi Pertumbuhan Normal',
    this.clusterId,
    this.estimatedTotalHst,
  });

  final int daysLeft;
  final DateTime inputDate;
  final String growthStage;
  final int stageId;
  final String clusterDesc;
  final int? clusterId;
  final int? estimatedTotalHst;

  DateTime get harvestDate => inputDate.add(Duration(days: daysLeft));
  bool get isReady => daysLeft <= 0 || stageId == 2;
}
