import '../../../prediction/domain/entities/prediction_request.dart';

/// Satu log prediksi yang tersimpan. Ini entitas bisnis riwayat,
/// bukan representasi tabel/JSON (itu tugas model di layer data).
class HistoryEntry {
  const HistoryEntry({
    required this.location,
    required this.inputDate,
    required this.daysLeft,
    required this.parameters,
  });

  final String location;
  final DateTime inputDate;
  final int daysLeft;
  final PredictionRequest parameters;

  DateTime get harvestDate => inputDate.add(Duration(days: daysLeft));
  bool get isReady => daysLeft <= 0;
}
