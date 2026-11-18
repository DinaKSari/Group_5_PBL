import '../../domain/entities/prediction_result.dart';

/// Representasi response JSON endpoint /predict (baik dari Flask langsung maupun via Laravel).
class PredictionResultModel {
  static PredictionResult fromJson(
    Map<String, dynamic> json,
    DateTime inputDate,
  ) {
    final rawDays = json['days_left'];
    if (rawDays is! num) {
      throw const FormatException(
        'Field days_left tidak ditemukan atau tidak valid.',
      );
    }

    final days = rawDays.toInt();
    final totalHst = (json['estimated_total_hst'] as num?)?.toInt();

    final cls = _asJsonMap(json['classification']);
    final stage = cls?['growth_stage']?.toString() ?? 'Vegetatif (Pembesaran)';
    final stageId = (cls?['stage_id'] as num?)?.toInt() ?? 1;

    final cluster = _asJsonMap(json['clustering']);
    final clusterId = (cluster?['cluster_id'] as num?)?.toInt();
    final profile = _asJsonMap(cluster?['profile']);
    final clusterDesc =
        profile?['description']?.toString() ?? 'Kondisi Pertumbuhan Normal';

    return PredictionResult(
      daysLeft: days,
      inputDate: inputDate,
      growthStage: stage,
      stageId: stageId,
      clusterDesc: clusterDesc,
      clusterId: clusterId,
      estimatedTotalHst: totalHst,
    );
  }

  static Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
