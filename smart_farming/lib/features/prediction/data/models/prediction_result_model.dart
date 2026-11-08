import '../../domain/entities/prediction_result.dart';

/// Representasi response JSON endpoint /predict.
class PredictionResultModel {
  static PredictionResult fromJson(Map<String, dynamic> json, DateTime inputDate) {
    final days = (json['days_left'] as num?)?.toInt() ?? 0;
    return PredictionResult(daysLeft: days, inputDate: inputDate);
  }
}
